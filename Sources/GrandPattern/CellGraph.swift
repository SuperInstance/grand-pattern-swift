import Foundation

public class CellGraph {
    public var rooms: [String: Room]
    public var edges: [(String, String)]
    public var bpm: Double
    public var tickCount: UInt64
    public var router: Router

    public init(bpm: Double = 120) {
        self.rooms = [:]
        self.edges = []
        self.bpm = bpm
        self.tickCount = 0
        self.router = Router()
    }

    public func addRoom(_ name: String) {
        if rooms[name] == nil {
            rooms[name] = Room(name: name)
        }
        router.addPort(name)
    }

    public func addEdge(_ from: String, _ to: String) {
        edges.append((from, to))
        router.addRoute(from: from, to: to)
    }

    public func tick() {
        tickCount += 1

        // Tick all rooms
        for (_, room) in rooms {
            room.tick()
        }

        // Diffuse vibes along edges
        for (from, to) in edges {
            guard let roomA = rooms[from], let roomB = rooms[to] else { continue }
            let blended = roomA.vibe.blend(with: roomB.vibe, ratio: 0.1)
            roomB.vibe = blended
        }

        // Send signals via router
        for (name, room) in rooms {
            let signal = Signal(source: name, payload: room.vibe.dims, timestamp: tickCount)
            let _ = router.send(signal)
        }
    }

    public func gossip() {
        // Each room sends murmur packets to connected neighbors
        for (from, to) in edges {
            guard let roomFrom = rooms[from], let roomTo = rooms[to] else { continue }
            for packet in roomFrom.murmur.outbox {
                roomTo.receiveMurmur(packet)
            }
            roomFrom.murmur.outbox.removeAll()
        }
    }

    public func fleetVibe() -> Vibe {
        guard !rooms.isEmpty else { return Vibe(dims: Array(repeating: 0.0, count: 16)) }
        let allDims = rooms.values.map { $0.vibe.dims }
        let mean = (0..<16).map { i in
            allDims.reduce(0.0) { $0 + $1[i] } / Double(allDims.count)
        }
        return Vibe(dims: mean).bounded()
    }

    public func fleetSurprise() -> Double {
        guard !rooms.isEmpty else { return 0 }
        return rooms.values.map { $0.currentSurprise() }.reduce(0, +) / Double(rooms.count)
    }

    public func detectAnomaly(threshold: Double = 1.0) -> [String] {
        return rooms.filter { $0.value.currentSurprise() > threshold }.map { $0.key }
    }
}
