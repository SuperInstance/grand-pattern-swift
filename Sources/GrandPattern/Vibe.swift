import Foundation

public struct Vibe {
    public var dims: [Double] // 16 elements

    public init(dims: [Double]? = nil) {
        if let d = dims {
            precondition(d.count == 16, "Vibe requires exactly 16 dimensions")
            self.dims = d
        } else {
            self.dims = (0..<16).map { _ in Double.random(in: -1...1) }
        }
    }

    public init(seed: Int) {
        var generator = SeededRandomGenerator(seed: seed)
        self.dims = (0..<16).map { _ in generator.next(in: -1...1) }
    }

    public func blend(with other: Vibe, ratio: Double) -> Vibe {
        let clamped = max(0, min(1, ratio))
        let blended = zip(dims, other.dims).map { selfDim, otherDim in
            selfDim * (1 - clamped) + otherDim * clamped
        }
        return Vibe(dims: blended).bounded()
    }

    public func distance(to other: Vibe) -> Double {
        sqrt(zip(dims, other.dims).map { ($0 - $1) * ($0 - $1) }.reduce(0, +))
    }

    public func diffuse(neighbors: [Vibe], weights: [Double], coeff: Double) -> Vibe {
        guard !neighbors.isEmpty else { return self }
        let w = weights.count == neighbors.count ? weights : Array(repeating: 1.0 / Double(neighbors.count), count: neighbors.count)
        let neighborMean = (0..<16).map { i in
            (0..<neighbors.count).reduce(0.0) { sum, j in sum + neighbors[j].dims[i] * w[j] }
        }
        let diff = zip(neighborMean, dims).map { $0 - $1 }
        let result = zip(dims, diff).map { $0 + coeff * $1 }
        return Vibe(dims: result).bounded()
    }

    public func qualitativeDescription() -> String {
        let labels = [
            "calm", "energetic", "warm", "cold", "bright", "dark",
            "smooth", "rough", "fast", "slow", "dense", "sparse",
            "harmonic", "chaotic", "rising", "falling"
        ]
        let top = zip(labels, dims).sorted { abs($0.1) > abs($1.1) }.prefix(3)
        let parts = top.map { label, val in
            "\(label)(\(String(format: "%+.2f", val)))"
        }
        return parts.joined(separator: ", ")
    }

    public var energy: Double {
        sqrt(dims.map { $0 * $0 }.reduce(0, +))
    }

    public func bounded() -> Vibe {
        Vibe(dims: dims.map { max(-1, min(1, $0)) })
    }
}

struct SeededRandomGenerator {
    private var state: UInt64
    init(seed: Int) {
        state = UInt64(bitPattern: Int64(truncatingIfNeeded: seed)) &+ 0x9E3779B97F4A7C15
    }
    mutating func next(in range: ClosedRange<Double>) -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let normalized = Double(state & 0x7FFFFFFFFFFFFFFF) / Double(UInt64(0x7FFFFFFFFFFFFFFF))
        return range.lowerBound + normalized * (range.upperBound - range.lowerBound)
    }
}
