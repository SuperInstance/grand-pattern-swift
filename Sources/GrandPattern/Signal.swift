import Foundation

public enum SignalAlgorithm: String, CaseIterable {
    case broadcast, roundRobin, random, priority, cascade, weighted
}

public struct Signal {
    public var source: String
    public var payload: [Double]
    public var algorithm: SignalAlgorithm
    public var priority: Double
    public var timestamp: UInt64

    public init(source: String, payload: [Double], algorithm: SignalAlgorithm = .broadcast, priority: Double = 1.0, timestamp: UInt64) {
        self.source = source
        self.payload = payload
        self.algorithm = algorithm
        self.priority = priority
        self.timestamp = timestamp
    }
}

public struct Port {
    public var name: String
    public var connections: [String]

    public init(name: String, connections: [String] = []) {
        self.name = name
        self.connections = connections
    }

    public mutating func connect(_ target: String) {
        if !connections.contains(target) {
            connections.append(target)
        }
    }
}

public struct Route {
    public var from: String
    public var to: String
    public var algorithm: SignalAlgorithm

    public init(from: String, to: String, algorithm: SignalAlgorithm = .broadcast) {
        self.from = from
        self.to = to
        self.algorithm = algorithm
    }
}

public class Router {
    public var ports: [String: Port]
    public var routes: [Route]
    public var deadband: Double
    public var history: [(String, [Double])]

    public init(deadband: Double = 0.001) {
        self.ports = [:]
        self.routes = []
        self.deadband = deadband
        self.history = []
    }

    public func addPort(_ name: String) {
        if ports[name] == nil {
            ports[name] = Port(name: name)
        }
    }

    public func addRoute(from: String, to: String, algorithm: SignalAlgorithm = .broadcast) {
        routes.append(Route(from: from, to: to, algorithm: algorithm))
        addPort(from)
        addPort(to)
        ports[from]?.connect(to)
    }

    public func send(_ signal: Signal) -> [(String, [Double])] {
        // Check deadband: skip if same as last signal from this source
        if let last = history.last(where: { $0.0 == signal.source }) {
            let diff = zip(last.1, signal.payload).map { abs($0 - $1) }.reduce(0, +)
            if diff < deadband {
                return [] // Suppressed by deadband
            }
        }
        history.append((signal.source, signal.payload))
        if history.count > 100 { history.removeFirst() }

        let matchingRoutes = routes.filter { $0.from == signal.source }
        var results: [(String, [Double])] = []

        switch signal.algorithm {
        case .broadcast:
            for route in matchingRoutes {
                results.append((route.to, signal.payload))
            }
        case .roundRobin:
            if let route = matchingRoutes.randomElement() {
                results.append((route.to, signal.payload))
            }
        case .random:
            if let route = matchingRoutes.randomElement() {
                results.append((route.to, signal.payload))
            }
        case .priority:
            let sorted = matchingRoutes.sorted { route1, route2 in
                (ports[route1.to]?.connections.count ?? 0) > (ports[route2.to]?.connections.count ?? 0)
            }
            if let route = sorted.first {
                results.append((route.to, signal.payload))
            }
        case .cascade:
            for route in matchingRoutes {
                let attenuated = signal.payload.map { $0 * 0.8 }
                results.append((route.to, attenuated))
            }
        case .weighted:
            for (i, route) in matchingRoutes.enumerated() {
                let weight = 1.0 / Double(i + 1)
                let weighted = signal.payload.map { $0 * weight }
                results.append((route.to, weighted))
            }
        }
        return results
    }
}
