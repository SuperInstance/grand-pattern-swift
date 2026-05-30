import Foundation

public class Room {
    public var name: String
    public var vibe: Vibe
    public var jepa: Jepa
    public var murmur: Murmur
    public var tickCount: UInt64

    public init(name: String) {
        self.name = name
        self.vibe = Vibe()
        self.jepa = Jepa()
        self.murmur = Murmur()
        self.tickCount = 0
    }

    public init(name: String, vibe: Vibe) {
        self.name = name
        self.vibe = vibe
        self.jepa = Jepa()
        self.murmur = Murmur()
        self.tickCount = 0
    }

    public func tick() {
        tickCount += 1
        // Perceive current vibe into Jepa
        jepa.perceive(vibe.dims, timestamp: tickCount)
        // Get prediction and compute surprise
        let prediction = jepa.predict()
        let _ = jepa.surprise(vibe.dims, prediction)

        // Create a murmur if energy is high enough
        if vibe.energy > 0.5 {
            murmur.create(origin: name, payload: vibe.dims, timestamp: tickCount)
        }

        // Process murmur decay
        murmur.processDecay()
    }

    public func receiveMurmur(_ packet: MurmurPacket) {
        murmur.receive(packet)
        // Influence vibe from incoming murmur
        if let incoming = murmur.inbox.last {
            let incomingVibe = Vibe(dims: incoming.payload).bounded()
            vibe = vibe.blend(with: incomingVibe, ratio: 0.1)
        }
    }

    public func diffuse(with neighbors: [Room], weights: [Double] = [], coeff: Double = 0.2) {
        let neighborVibes = neighbors.map { $0.vibe }
        let w = weights.isEmpty ? Array(repeating: 1.0 / Double(neighbors.count), count: neighbors.count) : weights
        vibe = vibe.diffuse(neighbors: neighborVibes, weights: w, coeff: coeff)
    }

    public func currentSurprise() -> Double {
        let prediction = jepa.predict()
        return jepa.surprise(vibe.dims, prediction)
    }
}
