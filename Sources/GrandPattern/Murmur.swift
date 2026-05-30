import Foundation

public struct MurmurPacket: CustomStringConvertible {
    public var origin: String
    public var payload: [Double]
    public var ttl: Int
    public var level: Int
    public var createdAt: UInt64

    public init(origin: String, payload: [Double], ttl: Int = 5, level: Int = 0, createdAt: UInt64) {
        self.origin = origin
        self.payload = payload
        self.ttl = ttl
        self.level = level
        self.createdAt = createdAt
    }

    public var isExpired: Bool { ttl <= 0 }

    public func decay() -> MurmurPacket {
        MurmurPacket(
            origin: origin,
            payload: payload.map { $0 * 0.9 }, // Attenuate
            ttl: ttl - 1,
            level: level + 1,
            createdAt: createdAt
        )
    }

    public var description: String {
        "Murmur(from=\(origin), ttl=\(ttl), level=\(level), energy=\(String(format: "%.3f", sqrt(payload.map { $0 * $0 }.reduce(0, +)))))"
    }
}

public class Murmur {
    public var inbox: [MurmurPacket]
    public var outbox: [MurmurPacket]

    public init() {
        self.inbox = []
        self.outbox = []
    }

    public func create(origin: String, payload: [Double], timestamp: UInt64) -> MurmurPacket {
        let packet = MurmurPacket(origin: origin, payload: payload, ttl: 5, level: 0, createdAt: timestamp)
        outbox.append(packet)
        return packet
    }

    public func receive(_ packet: MurmurPacket) {
        guard !packet.isExpired else { return }
        inbox.append(packet)
    }

    public func processDecay() {
        inbox = inbox.map { $0.decay() }.filter { !$0.isExpired }
        outbox = outbox.map { $0.decay() }.filter { !$0.isExpired }
    }
}

public struct GossipRound {
    public var round: Int
    public var packetsSent: Int
    public var packetsReceived: Int

    public init(round: Int, packetsSent: Int, packetsReceived: Int) {
        self.round = round
        self.packetsSent = packetsSent
        self.packetsReceived = packetsReceived
    }
}
