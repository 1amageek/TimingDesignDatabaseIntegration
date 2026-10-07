import CircuiteFoundation
import DesignDatabaseCore
import LogicDesignDatabaseSchema
import ParasiticDesignDatabaseSchema
import Foundation
import StandardCellLibraryDesignDatabaseSchema
import Testing
import TimingCore
import TimingDesignDatabaseSchema

@Suite("Timing DesignDatabase schema")
struct TimingDatabaseSchemaTests {
    @Test("timing design and dependency bindings round-trip canonically")
    func canonicalRoundTrip() throws {
        let state = try makeState()
        let data = try TimingDatabaseCanonicalCodec.encode(state)

        #expect(try TimingDatabaseCanonicalCodec.decode(data) == state)
        #expect(state.design.ports.map(\.name) == ["clk", "out"])
        #expect(state.libraries.map(\.name) == ["fixture-library"])
    }

    @Test("canonical timing state preserves distributed CAP source inventory without reduction")
    func distributedParasiticsRoundTrip() throws {
        let fixture = try makeBindings()
        let inventory = try SPEFParser().parse(Data("*D_NET out 10\n*CAP\n1 out:1 3\n2 out:1 out:2 7\n*RES\n1 out:1 out:2 100\n*END\n".utf8))
        let binding = try ParasiticDatabaseFacetSourceBinding(
            sourceRevision: fixture.logic.sourceRevision, sourceRootDigest: timingDigest("14"))
        let state = try TimingDatabaseState(sourceLogic: fixture.logic, sourceLibrary: fixture.library,
            sourceParasitics: binding, designArtifact: fixture.designArtifact,
            constraintArtifact: fixture.constraintArtifact, design: fixture.design,
            constraints: fixture.constraints, libraries: fixture.libraries, parasitics: inventory)
        let decoded = try TimingDatabaseCanonicalCodec.decode(TimingDatabaseCanonicalCodec.encode(state))
        #expect(decoded.parasitics == inventory)
        #expect(decoded.parasitics?.networks.first?.capacitances.last?.second?.name == "out:2")
        #expect(decoded.parasitics?.networks.first?.declaredCapacitance == 10)
        #expect(decoded.parasitics?.networks.first?.resistanceInventory == 100)
        var old = try #require(JSONSerialization.jsonObject(with: TimingDatabaseCanonicalCodec.encode(state)) as? [String: Any])
        old["schemaVersion"] = 1
        #expect(throws: TimingDatabaseSchemaError.self) {
            _ = try TimingDatabaseCanonicalCodec.decode(JSONSerialization.data(withJSONObject: old))
        }
    }

    @Test("invalid clocks are rejected before candidate preparation")
    func invalidClockIsRejected() throws {
        let fixture = try makeBindings()
        let invalid = TimingConstraintSet(
            clocks: [
                TimingConstraintSet.Clock(
                    name: "clk",
                    source: "missing",
                    period: -1
                ),
            ]
        )

        #expect(throws: TimingDatabaseSchemaError.self) {
            try TimingDatabaseState(
                sourceLogic: fixture.logic,
                sourceLibrary: fixture.library,
                designArtifact: fixture.designArtifact,
                constraintArtifact: fixture.constraintArtifact,
                design: fixture.design,
                constraints: invalid,
                libraries: fixture.libraries
            )
        }
    }

    @Test("parasitic data cannot exist without an exact parasitic root")
    func parasiticDataRequiresBinding() throws {
        let fixture = try makeBindings()

        #expect(throws: TimingDatabaseSchemaError.self) {
            try TimingDatabaseState(
                sourceLogic: fixture.logic,
                sourceLibrary: fixture.library,
                designArtifact: fixture.designArtifact,
                constraintArtifact: fixture.constraintArtifact,
                design: fixture.design,
                constraints: fixture.constraints,
                libraries: fixture.libraries,
                parasitics: TimingParasitics(
                    designName: "top",
                    networks: [
                        TimingParasitics.Network(name: "clk"),
                    ]
                )
            )
        }
    }
}

private struct TimingBindings {
    let logic: LogicDatabaseExactFacetBinding
    let library: StandardCellLibraryFacetSourceBinding
    let designArtifact: ArtifactReference
    let constraintArtifact: ArtifactReference
    let design: TimingDesign
    let constraints: TimingConstraintSet
    let libraries: [TimingLibrary]
}

private func makeState() throws -> TimingDatabaseState {
    let fixture = try makeBindings()
    return try TimingDatabaseState(
        sourceLogic: fixture.logic,
        sourceLibrary: fixture.library,
        designArtifact: fixture.designArtifact,
        constraintArtifact: fixture.constraintArtifact,
        design: fixture.design,
        constraints: fixture.constraints,
        libraries: fixture.libraries
    )
}

private func makeBindings() throws -> TimingBindings {
    let databaseID = try DesignDatabaseID(high: 31, low: 32)
    let revision = DesignRevisionReference(
        databaseID: databaseID,
        revisionID: DesignRevisionID(high: 33, low: 34)
    )
    let logic = LogicDatabaseExactFacetBinding(
        sourceRevision: revision,
        sourceFacet: .gate,
        sourceRootDigest: try timingDigest("10")
    )
    let library = try StandardCellLibraryFacetSourceBinding(
        sourceRevision: revision,
        sourceRootDigest: try timingDigest("11")
    )
    let design = TimingDesign(
        topDesignName: "top",
        ports: [
            TimingDesign.Port(name: "out", direction: .output),
            TimingDesign.Port(name: "clk", direction: .input, clock: "clk"),
        ],
        instances: [],
        nets: [
            TimingDesign.Net(name: "out"),
            TimingDesign.Net(name: "clk"),
        ]
    )
    let constraints = TimingConstraintSet(
        clocks: [
            TimingConstraintSet.Clock(
                name: "clk",
                source: "clk",
                period: 1e-9
            ),
        ]
    )
    return TimingBindings(
        logic: logic,
        library: library,
        designArtifact: try timingArtifact(
            byte: "12",
            kind: .netlist,
            format: .verilog
        ),
        constraintArtifact: try timingArtifact(
            byte: "13",
            kind: .constraints,
            format: .sdc
        ),
        design: design,
        constraints: constraints,
        libraries: [TimingLibrary(name: "fixture-library")]
    )
}

private func timingArtifact(
    byte: String,
    kind: ArtifactKind,
    format: ArtifactFormat
) throws -> ArtifactReference {
    try ArtifactReference(
        digest: timingDigest(byte),
        byteCount: 100,
        descriptor: ArtifactDescriptor(
            role: .input,
            kind: kind,
            format: format
        )
    )
}

private func timingDigest(_ byte: String) throws -> ContentDigest {
    try ContentDigest(
        algorithm: .sha256,
        hexadecimalValue: String(repeating: byte, count: 32)
    )
}
