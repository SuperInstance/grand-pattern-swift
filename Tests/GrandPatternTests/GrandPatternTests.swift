import XCTest
@testable import GrandPattern

final class GrandPatternTests: XCTestCase {

    // MARK: - Vibe Tests (1-5)

    func testVibeInit() {
        let v = Vibe()
        XCTAssertEqual(v.dims.count, 16)
        for d in v.dims {
            XCTAssertGreaterThanOrEqual(d, -1)
            XCTAssertLessThanOrEqual(d, 1)
        }
    }

    func testVibeBlend() {
        let a = Vibe(dims: Array(repeating: 0.0, count: 16))
        let b = Vibe(dims: Array(repeating: 1.0, count: 16))
        let blended = a.blend(with: b, ratio: 0.5)
        for d in blended.dims {
            XCTAssertEqual(d, 0.5, accuracy: 0.001)
        }
    }

    func testVibeDistance() {
        let a = Vibe(dims: Array(repeating: 0.0, count: 16))
        let b = Vibe(dims: Array(repeating: 1.0, count: 16))
        let dist = a.distance(to: b)
        XCTAssertEqual(dist, 4.0, accuracy: 0.001) // sqrt(16)
    }

    func testVibeDiffuse() {
        let center = Vibe(dims: Array(repeating: 0.0, count: 16))
        let neighbors = [Vibe(dims: Array(repeating: 1.0, count: 16))]
        let diffused = center.diffuse(neighbors: neighbors, weights: [1.0], coeff: 0.5)
        for d in diffused.dims {
            XCTAssertEqual(d, 0.5, accuracy: 0.001)
        }
    }

    func testVibeDescription() {
        let v = Vibe(dims: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0].map { Double($0) })
        let desc = v.qualitativeDescription()
        XCTAssertTrue(desc.contains("calm"))
    }

    // MARK: - Jepa Tests (6-10)

    func testJepaPerceive() {
        let jepa = Jepa(window: 10)
        let data = Array(repeating: 0.5, count: 16)
        jepa.perceive(data, timestamp: 1)
        XCTAssertEqual(jepa.dbIn.count, 1)
        XCTAssertEqual(jepa.dbOut.count, 1)
    }

    func testJepaPredict() {
        let jepa = Jepa(window: 10)
        let data = Array(repeating: 0.5, count: 16)
        jepa.perceive(data, timestamp: 1)
        jepa.perceive(data, timestamp: 2)
        let prediction = jepa.predict()
        XCTAssertEqual(prediction.count, 16)
    }

    func testJepaSurprise() {
        let jepa = Jepa()
        let a = Array(repeating: 0.0, count: 16)
        let b = Array(repeating: 1.0, count: 16)
        let s = jepa.surprise(a, b)
        XCTAssertEqual(s, 1.0, accuracy: 0.001)
    }

    func testJepaConservation() {
        let jepa = Jepa(window: 100)
        for i in 0..<5 {
            jepa.perceive(Array(repeating: Double(i) * 0.1, count: 16), timestamp: UInt64(i))
        }
        XCTAssertTrue(jepa.checkConservation())
    }

    func testJepaGC() {
        let jepa = Jepa(window: 100)
        // Add a near-zero prediction
        jepa.perceive(Array(repeating: 0.0, count: 16), timestamp: 1)
        jepa.perceive(Array(repeating: 0.5, count: 16), timestamp: 2)
        let before = jepa.dbOut.count
        jepa.gc(threshold: 0.1)
        // At least the zero-energy one should be removed
        XCTAssertLessThanOrEqual(jepa.dbOut.count, before)
    }

    // MARK: - Murmur Tests (11-13)

    func testMurmurCreate() {
        let murmur = Murmur()
        let packet = murmur.create(origin: "room1", payload: Array(repeating: 0.5, count: 16), timestamp: 1)
        XCTAssertEqual(packet.origin, "room1")
        XCTAssertEqual(packet.ttl, 5)
        XCTAssertEqual(murmur.outbox.count, 1)
    }

    func testMurmurDecay() {
        var packet = MurmurPacket(origin: "test", payload: Array(repeating: 1.0, count: 16), ttl: 2, level: 0, createdAt: 1)
        packet = packet.decay()
        XCTAssertEqual(packet.ttl, 1)
        XCTAssertFalse(packet.isExpired)
        packet = packet.decay()
        XCTAssertTrue(packet.isExpired)
    }

    func testMurmurGossip() {
        let murmur = Murmur()
        _ = murmur.create(origin: "a", payload: Array(repeating: 0.5, count: 16), timestamp: 1)
        XCTAssertEqual(murmur.outbox.count, 1)

        // Simulate gossip by transferring outbox to another murmur's inbox
        let murmur2 = Murmur()
        for packet in murmur.outbox {
            murmur2.receive(packet)
        }
        XCTAssertEqual(murmur2.inbox.count, 1)

        // Process decay
        murmur2.processDecay()
        XCTAssertEqual(murmur2.inbox.count, 1) // ttl=5, still alive after 1 decay
    }

    // MARK: - Tick Tests (14-15)

    func testTickSchedule() {
        var schedule = TickSchedule()
        var fired = false
        schedule.schedule(name: "test", tMinus: 3) { fired = true }
        let r1 = schedule.tick()
        XCTAssertTrue(r1.isEmpty)
        XCTAssertFalse(fired)
        let r2 = schedule.tick()
        XCTAssertTrue(r2.isEmpty)
        let r3 = schedule.tick()
        XCTAssertEqual(r3, ["test"])
        XCTAssertTrue(fired)
    }

    func testTickTempo() {
        let tempo = Tempo(bpm: 120)
        XCTAssertEqual(tempo.intervalSeconds, 0.5, accuracy: 0.001)
        XCTAssertEqual(tempo.ticks(for: 1.0), 2)
        XCTAssertEqual(tempo.ticks(for: 2.0), 4)
    }

    // MARK: - Router Tests (16-17)

    func testRouterSend() {
        let router = Router()
        router.addRoute(from: "a", to: "b")
        router.addRoute(from: "a", to: "c")
        let signal = Signal(source: "a", payload: Array(repeating: 0.5, count: 16), timestamp: 1)
        let results = router.send(signal)
        XCTAssertEqual(results.count, 2)
        let destinations = results.map { $0.0 }
        XCTAssertTrue(destinations.contains("b"))
        XCTAssertTrue(destinations.contains("c"))
    }

    func testRouterDeadband() {
        let router = Router(deadband: 0.01)
        router.addRoute(from: "a", to: "b")
        let payload = Array(repeating: 0.5, count: 16)
        let s1 = Signal(source: "a", payload: payload, timestamp: 1)
        let s2 = Signal(source: "a", payload: payload, timestamp: 2)
        let r1 = router.send(s1)
        XCTAssertEqual(r1.count, 1) // First send goes through
        let r2 = router.send(s2)
        XCTAssertEqual(r2.count, 0) // Suppressed by deadband (identical)
    }

    // MARK: - CellGraph Tests (18-20)

    func testCellGraphTick() {
        let graph = CellGraph()
        graph.addRoom("a")
        graph.addRoom("b")
        graph.addEdge("a", "b")
        let vibeBefore = graph.rooms["b"]!.vibe.dims
        graph.tick()
        let vibeAfter = graph.rooms["b"]!.vibe.dims
        // Vibe should have been influenced by neighbor
        XCTAssertNotEqual(vibeBefore, vibeAfter)
    }

    func testCellGraphGossip() {
        let graph = CellGraph()
        graph.addRoom("a")
        graph.addRoom("b")
        graph.addEdge("a", "b")

        // Force high energy so room "a" creates a murmur
        graph.rooms["a"]!.vibe = Vibe(dims: Array(repeating: 0.9, count: 16))
        graph.tick()
        graph.gossip()
        // Room "b" should have received murmur from "a"
        XCTAssertFalse(graph.rooms["b"]!.murmur.inbox.isEmpty)
    }

    func testCellGraphFleetVibe() {
        let graph = CellGraph()
        graph.addRoom("a")
        graph.addRoom("b")
        graph.rooms["a"]!.vibe = Vibe(dims: Array(repeating: 0.0, count: 16))
        graph.rooms["b"]!.vibe = Vibe(dims: Array(repeating: 1.0, count: 16))
        let fleet = graph.fleetVibe()
        for d in fleet.dims {
            XCTAssertEqual(d, 0.5, accuracy: 0.001)
        }
    }

    func testCellGraphAnomaly() {
        let graph = CellGraph()
        graph.addRoom("normal")
        graph.addRoom("anomaly")
        // Feed stable data to normal room
        graph.rooms["normal"]!.vibe = Vibe(dims: Array(repeating: 0.0, count: 16))
        // Feed different stable data to anomaly room
        graph.rooms["anomaly"]!.vibe = Vibe(dims: Array(repeating: 0.9, count: 16))
        // Tick several times to build up prediction context
        for _ in 0..<5 { graph.tick() }
        // Now suddenly shift anomaly room's vibe to something very different
        graph.rooms["anomaly"]!.vibe = Vibe(dims: Array(repeating: -0.9, count: 16))
        graph.tick()
        let anomalies = graph.detectAnomaly(threshold: 0.1)
        XCTAssertTrue(anomalies.contains("anomaly"))
    }

    func testVibeEnergy() {
        let v = Vibe(dims: Array(repeating: 0.5, count: 16))
        let expected = sqrt(16 * 0.25)
        XCTAssertEqual(v.energy, expected, accuracy: 0.001)
    }

    func testVibeBounded() {
        let v = Vibe(dims: Array(repeating: 2.0, count: 16))
        let bounded = v.bounded()
        for d in bounded.dims {
            XCTAssertLessThanOrEqual(d, 1.0)
            XCTAssertGreaterThanOrEqual(d, -1.0)
        }
    }
}
