import Foundation

public struct TMinusEvent {
    public var name: String
    public var tMinus: Int // ticks remaining
    public var action: () -> Void

    public init(name: String, tMinus: Int, action: @escaping () -> Void) {
        self.name = name
        self.tMinus = tMinus
        self.action = action
    }

    public mutating func tick() -> Bool {
        tMinus -= 1
        if tMinus <= 0 {
            action()
            return true
        }
        return false
    }
}

public struct TickSchedule {
    public var events: [TMinusEvent]
    public var tickCount: UInt64

    public init() {
        self.events = []
        self.tickCount = 0
    }

    public mutating func schedule(name: String, tMinus: Int, action: @escaping () -> Void) {
        events.append(TMinusEvent(name: name, tMinus: tMinus, action: action))
    }

    public mutating func tick() -> [String] {
        tickCount += 1
        var fired: [String] = []
        events = events.compactMap { event in
            var e = event
            if e.tick() {
                fired.append(e.name)
                return nil
            }
            return e
        }
        return fired
    }
}

public struct Tempo {
    public var bpm: Double

    public init(bpm: Double = 120) {
        self.bpm = bpm
    }

    public var intervalSeconds: Double {
        60.0 / bpm
    }

    public var intervalMs: Double {
        intervalSeconds * 1000
    }

    public func ticks(for durationSeconds: Double) -> Int {
        Int(durationSeconds / intervalSeconds)
    }
}
