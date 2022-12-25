extension StringProtocol {
    func dropPrefix(_ prefixes: String...) -> SubSequence? {
        for prefix in prefixes {
            if hasPrefix(prefix) {
                return dropFirst(prefix.count)
            }
        }
        return nil
    }

    private func parseInternal<T>(while predicate: (Character) -> Bool, transform: (SubSequence) -> T) -> (SubSequence, T)? {
        let parsed = prefix(while: predicate)
        guard !parsed.isEmpty else {
            return nil
        }
        return (dropFirst(parsed.count), transform(parsed))
    }

    func parseWord() -> (SubSequence, String)? {
        return parseInternal(while: \.isLetter, transform: { String($0) })
    }

    func parseList() -> (SubSequence, [String])? {
        // Can't easily get rid of let warning?
        guard var (rest, element) = parseWord() else {
            return nil
        }
        var result = [element]
        while let next = rest.dropPrefix(", ") {
            guard let (next, element) = next.parseWord() else {
                return nil
            }
            rest = next
            result.append(element)
        }
        return (rest, result)
    }

    func parseInt() -> (SubSequence, Int)? {
        return parseInternal(while: { "0123456789".contains($0) }, transform: { Int($0)! })
    }
}

struct PriorityQueue<T> {
    var heap: [(Int, T)] = []

    mutating func push(priority: Int, element: T) {
        var i = heap.endIndex
        heap.append((priority, element))
        while i > 0 {
            if heap[i / 2].0 > heap[i].0 {
                heap.swapAt(i / 2, i)
                i /= 2
            } else {
                break
            }
        }
    }

    mutating func pop() -> T? {
        guard let result = heap.first else {
            return nil
        }
        let tail = heap.removeLast()
        if !heap.isEmpty {
            heap[0] = tail
            var i = heap.startIndex
            while true {
                var child = 2 * i + 1
                if child + 1 < heap.count {
                    child = heap[child].0 < heap[child + 1].0 ? child : child + 1
                } else if child >= heap.count {
                    break
                }
                if heap[i].0 > heap[child].0 {
                    heap.swapAt(i, child)
                    i = child
                } else {
                    break
                }
            }
        }
        return result.1
    }
}

struct Valve {
    var name: String
    var flowRate: Int
    var neighbors: [String]
}

struct State {
    var path: [Int]
    var remainingTime: Int
    var cost: Int
}

struct Graph {
    var edges: [[Int]]
    var flowRates: [Int]
    var names: [String]
    var terminal: Int { edges.count - 1 }

    init(fromValves valves: [Valve]) {
        flowRates = valves.map(\.flowRate)
        names = valves.map(\.name)

        // Floyd-Warshall to make fully connected graph.
        edges = Array(repeating: Array(repeating: Int.max / 2, count: valves.count), count: valves.count)
        for valve in valves {
            for neighbor in valve.neighbors {
                guard let u = names.firstIndex(of: valve.name),
                      let v = names.firstIndex(of: neighbor) else {
                    fatalError()
                }
                edges[u][v] = 1
            }
        }
        for v in edges.indices {
            edges[v][v] = 0
        }
        for k in edges.indices {
            for i in edges.indices {
                for j in edges.indices {
                    edges[i][j] = min(edges[i][j], edges[i][k] + edges[k][j])
                }
            }
        }

        // Remove trivial nodes.
        let start = names.firstIndex(of: "AA")
        let trivialNodes = flowRates
            .enumerated()
            .compactMap({ offset, flowRate in flowRate == 0 && offset != start ? offset : nil })
            .reversed()
        for i in trivialNodes {
            flowRates.remove(at: i)
            names.remove(at: i)
            edges.remove(at: i)
        }
        for i in edges.indices {
            for j in trivialNodes {
                edges[i].remove(at: j)
            }
            assert(edges[i].count == edges.count)
        }

        // Assume every visit opens the valve; add in this weight.
        for i in edges.indices {
            for j in edges.indices {
                edges[i][j] += 1
            }
        }
    }

    func pressure(ofPath path: [Int], time: Int) -> Int {
        assert(flowRates[path.first!] == 0)
        var result = 0
        var remainingTime = time
        for (from, to) in zip(path, path.dropFirst()) {
            remainingTime -= edges[from][to]
            precondition(remainingTime > 0)
            result += flowRates[to] * remainingTime
        }
        return result
    }

    // Aggregate flow rate of unopened valves; notably always non-negative. Used
    // to calculate path opportunity cost (cumulative residual over time) and as
    // an admissible (never overshoots cost) and consistent (triangle
    // inequality) heuristic.
    private func residualFlowRate(opened: [Int]) -> Int {
        var result = 0
        for i in flowRates.indices {
            if !opened.contains(i) {
                result += flowRates[i]
            }
        }
        return result
    }

    // A*
    func search(initial: State, restrictedTo indices: [Int]? = nil) -> State? {
        var fringe = PriorityQueue<State>()
        fringe.push(priority: residualFlowRate(opened: initial.path), element: initial)
        while let current = fringe.pop() {
            if current.remainingTime == 0 {
                return current
            }
            let residual = residualFlowRate(opened: current.path)
            for i in indices ?? Array(edges.indices) {
                let transitionTime = edges[current.path.last!][i]
                guard !current.path.contains(i),  // do not revisit nodes
                    current.remainingTime >= transitionTime else {
                    continue
                }
                let state = State(
                    path: current.path + [i],
                    remainingTime: current.remainingTime - transitionTime,
                    cost: current.cost + transitionTime * residual)
                fringe.push(priority: state.cost + residualFlowRate(opened: state.path), element: state)
            }
            // Idle remaining time.
            let state = State(path: current.path, remainingTime: 0, cost: current.cost + current.remainingTime * residual)
            fringe.push(priority: state.cost, element: state)
        }
        return nil
    }
}

func partitionings(_ base: some Collection<Int>) -> [([Int], [Int])] {
    if let option = base.first {
        let sub = partitionings(base.dropFirst())
        return sub.map({ ($0.0 + [option], $0.1) }) + sub.map({ ($0.0, $0.1 + [option]) })
    } else {
        return [([], [])]
    }
}

var valves: [Valve] = []
while let line = readLine() {
    guard let line = line.dropPrefix("Valve "),
          let (line, name) = line.parseWord(),
          let line = line.dropPrefix(" has flow rate="),
          let (line, flowRate) = line.parseInt(),
          let line = line.dropPrefix("; tunnels lead to valves ", "; tunnel leads to valve "),
          let (line, neighbors) = line.parseList(),
          line.isEmpty else {
        fatalError()
    }
    valves.append(Valve(name: name, flowRate: flowRate, neighbors: neighbors))
}

let graph = Graph(fromValves: valves)
let start = graph.names.firstIndex(of: "AA")!

let p1 = graph.search(initial: State(path: [start], remainingTime: 30, cost: 0))!
print(graph.pressure(ofPath: p1.path, time: 30))

var p2 = 0
for (alice, bob) in partitionings(graph.edges.indices) {
    let aliceState = graph.search(initial: State(path: [start], remainingTime: 26, cost: 0), restrictedTo: alice)!
    let bobState = graph.search(initial: State(path: [start], remainingTime: 26, cost: 0), restrictedTo: bob)!
    let pressure = graph.pressure(ofPath: aliceState.path, time: 26) + graph.pressure(ofPath: bobState.path, time: 26)
    p2 = max(p2, pressure)
}
print(p2)
