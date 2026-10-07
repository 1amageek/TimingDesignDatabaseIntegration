import CircuiteFoundation
import LogicDesignDatabaseSchema
import ParasiticDesignDatabaseSchema
import StandardCellLibraryDesignDatabaseSchema
import TimingCore

public struct TimingDatabaseState: Sendable, Hashable, Codable {
    public static let currentSchemaVersion = 2

    public let schemaVersion: Int
    public let sourceLogic: LogicDatabaseExactFacetBinding
    public let sourceLibrary: StandardCellLibraryFacetSourceBinding
    public let sourceParasitics: ParasiticDatabaseFacetSourceBinding?
    public let designArtifact: ArtifactReference
    public let constraintArtifact: ArtifactReference
    public let design: TimingDesign
    public let constraints: TimingConstraintSet
    public let libraries: [TimingLibrary]
    public let parasitics: TimingParasitics?
    public let metadata: [String: String]

    public init(
        sourceLogic: LogicDatabaseExactFacetBinding,
        sourceLibrary: StandardCellLibraryFacetSourceBinding,
        sourceParasitics: ParasiticDatabaseFacetSourceBinding? = nil,
        designArtifact: ArtifactReference,
        constraintArtifact: ArtifactReference,
        design: TimingDesign,
        constraints: TimingConstraintSet,
        libraries: [TimingLibrary],
        parasitics: TimingParasitics? = nil,
        metadata: [String: String] = [:]
    ) throws(TimingDatabaseSchemaError) {
        schemaVersion = Self.currentSchemaVersion
        self.sourceLogic = sourceLogic
        self.sourceLibrary = sourceLibrary
        self.sourceParasitics = sourceParasitics
        self.designArtifact = designArtifact
        self.constraintArtifact = constraintArtifact
        self.design = Self.canonical(design)
        self.constraints = Self.canonical(constraints)
        self.libraries = libraries.map(Self.canonical).sorted {
            $0.name < $1.name
        }
        self.parasitics = parasitics.map(Self.canonical)
        self.metadata = metadata
        try validate()
    }

    public func validate() throws(TimingDatabaseSchemaError) {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw .unsupportedSchemaVersion(schemaVersion)
        }
        do {
            try sourceLogic.validate()
            try sourceLibrary.validate()
            try sourceParasitics?.validate()
        } catch {
            throw .invalidSourceBinding(reason: String(describing: error))
        }
        guard sourceLogic.sourceFacet == .gate else {
            throw .invalidSourceBinding(reason: "Timing must bind the exact gate facet.")
        }
        let revision = sourceLogic.sourceRevision
        guard sourceLibrary.sourceRevision == revision,
              sourceParasitics?.sourceRevision == nil
                || sourceParasitics?.sourceRevision == revision else {
            throw .invalidSourceBinding(
                reason: "All timing dependencies must bind one exact base revision."
            )
        }
        guard sourceParasitics == nil || parasitics != nil,
              sourceParasitics != nil || parasitics == nil else {
            throw .invalidSourceBinding(
                reason: "Timing parasitic data and its exact source binding must be present together."
            )
        }
        guard designArtifact.descriptor.role == .input,
              designArtifact.descriptor.kind == .netlist,
              [.verilog, .systemVerilog].contains(designArtifact.descriptor.format) else {
            throw .invalidArtifactDescriptor(role: "design")
        }
        guard constraintArtifact.descriptor.role == .input,
              constraintArtifact.descriptor.kind == .constraints,
              constraintArtifact.descriptor.format == .sdc else {
            throw .invalidArtifactDescriptor(role: "constraints")
        }
        let report = TimingCanonicalValidator().validate(
            design: design,
            constraints: constraints,
            libraries: libraries,
            parasitics: parasitics
        )
        guard report.isValid else {
            throw .invalidTimingState(report.findings.map {
                [$0.code, $0.summary, $0.entity].compactMap { $0 }.joined(separator: ": ")
            })
        }
        guard design == Self.canonical(design),
              constraints == Self.canonical(constraints),
              libraries == libraries.map(Self.canonical).sorted(by: {
                  $0.name < $1.name
              }),
              parasitics == parasitics.map(Self.canonical) else {
            throw .nonCanonicalOrdering
        }
    }

    private static func canonical(_ source: TimingDesign) -> TimingDesign {
        TimingDesign(
            topDesignName: source.topDesignName,
            ports: source.ports.sorted { $0.name < $1.name },
            instances: source.instances.sorted { $0.name < $1.name },
            nets: source.nets.sorted { $0.name < $1.name }
        )
    }

    private static func canonical(
        _ source: TimingConstraintSet
    ) -> TimingConstraintSet {
        TimingConstraintSet(
            modeID: source.modeID,
            clocks: source.clocks.sorted { $0.name < $1.name },
            generatedClocks: source.generatedClocks.sorted { $0.name < $1.name },
            inputDelays: source.inputDelays.sorted(by: delayOrder),
            outputDelays: source.outputDelays.sorted(by: delayOrder),
            caseAnalyses: source.caseAnalyses.sorted { $0.target < $1.target },
            exceptions: source.exceptions,
            pathGroups: source.pathGroups.sorted { $0.name < $1.name },
            clockGroups: source.clockGroups,
            defaultInputSlew: source.defaultInputSlew,
            defaultOutputLoad: source.defaultOutputLoad
        )
    }

    private static func canonical(_ source: TimingLibrary) -> TimingLibrary {
        var cells: [String: TimingCell] = [:]
        for (name, sourceCell) in source.cells {
            cells[name] = TimingCell(
                name: sourceCell.name,
                area: sourceCell.area,
                pins: sourceCell.pins.sorted { $0.name < $1.name },
                arcs: sourceCell.arcs.sorted {
                    ($0.fromPin, $0.toPin, $0.isConstraint ? 1 : 0)
                        < ($1.fromPin, $1.toPin, $1.isConstraint ? 1 : 0)
                },
                sequentialModel: sourceCell.sequentialModel,
                powerModel: sourceCell.powerModel
            )
        }
        return TimingLibrary(
            name: source.name,
            timeUnitScale: source.timeUnitScale,
            capacitanceUnitScale: source.capacitanceUnitScale,
            powerUnitScale: source.powerUnitScale,
            cells: cells,
            operatingConditions: source.operatingConditions
        )
    }

    private static func canonical(_ source: TimingParasitics) -> TimingParasitics {
        TimingParasitics(
            designName: source.designName,
            networks: source.networks.sorted { $0.name < $1.name }.map { network in
                .init(name: network.name, declaredCapacitance: network.declaredCapacitance,
                      resistanceInventory: network.resistanceInventory,
                      capacitances: network.capacitances.sorted { $0.source < $1.source })
            }
        )
    }

    private static func delayOrder(
        _ lhs: TimingConstraintSet.PortDelay,
        _ rhs: TimingConstraintSet.PortDelay
    ) -> Bool {
        (lhs.port, lhs.clock ?? "", lhs.isMax ? 1 : 0)
            < (rhs.port, rhs.clock ?? "", rhs.isMax ? 1 : 0)
    }
}
