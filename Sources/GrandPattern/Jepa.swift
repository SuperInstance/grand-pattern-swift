import Foundation

public class VectorDb {
    public private(set) var vectors: [[Double]]
    public private(set) var timestamps: [UInt64]

    public init() {
        self.vectors = []
        self.timestamps = []
    }

    public func insert(_ vector: [Double], timestamp: UInt64) {
        vectors.append(vector)
        timestamps.append(timestamp)
    }

    public var count: Int { vectors.count }

    public func remove(at index: Int) {
        guard index >= 0, index < vectors.count else { return }
        vectors.remove(at: index)
        timestamps.remove(at: index)
    }
}

public class Jepa {
    public var dbIn: VectorDb
    public var dbOut: VectorDb
    public var window: Int

    public init(window: Int = 10) {
        self.dbIn = VectorDb()
        self.dbOut = VectorDb()
        self.window = window
    }

    public func perceive(_ data: [Double], timestamp: UInt64) {
        dbIn.insert(data, timestamp: timestamp)
        let prediction = predictInternal(from: data)
        dbOut.insert(prediction, timestamp: timestamp)

        // Keep window size
        while dbIn.count > window { dbIn.remove(at: 0) }
        while dbOut.count > window { dbOut.remove(at: 0) }
    }

    public func predict() -> [Double] {
        guard let last = dbIn.vectors.last else {
            return Array(repeating: 0.0, count: 16)
        }
        return predictInternal(from: last)
    }

    private func predictInternal(from data: [Double]) -> [Double] {
        // Simple predictive coding: extrapolate trend from recent history
        guard dbIn.count >= 2 else {
            return data // Identity if not enough context
        }
        let prev = dbIn.vectors[dbIn.count - 1]
        let prevPrev = dbIn.vectors[dbIn.count - 2]
        // Linear extrapolation: next = current + (current - previous)
        return zip(data, zip(prev, prevPrev).map { $0 - $1 }).map { $0 + $1 * 0.5 }
    }

    public func surprise(_ a: [Double], _ b: [Double]) -> Double {
        let diff = zip(a, b).map { ($0 - $1) * ($0 - $1) }.reduce(0.0, +)
        return sqrt(diff / Double(max(a.count, 1)))
    }

    public func checkConservation(tolerance: Int = 2) -> Bool {
        let inCount = dbIn.count
        let outCount = dbOut.count
        return abs(inCount - outCount) <= tolerance
    }

    public func gc(threshold: Double = 0.01) {
        // Remove predictions with very low energy (near-zero vectors)
        var keepIndices: [Int] = []
        for i in 0..<dbOut.count {
            let energy = sqrt(dbOut.vectors[i].map { $0 * $0 }.reduce(0, +))
            if energy >= threshold {
                keepIndices.append(i)
            }
        }
        let newVectors = keepIndices.map { dbOut.vectors[$0] }
        let newTimestamps = keepIndices.map { dbOut.timestamps[$0] }
        dbOut = VectorDb()
        for i in 0..<newVectors.count {
            dbOut.insert(newVectors[i], timestamp: newTimestamps[i])
        }
    }
}
