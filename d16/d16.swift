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

struct PriorityQueue2<T> {
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

struct PriorityQueue<T> {
    var array: [(Int, T)] = []

    mutating func push(priority: Int, element: T) {
        array.append((priority, element))
    }

    mutating func pop() -> T? {
        array.sort(by: { $0.0 < $1.0 })
        return array.isEmpty ? nil : array.removeFirst().1
    }
}

struct Valve {
    var name: String
    var flowRate: Int
    var neighbors: [String]
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

    // XXX
    func pressure(ofPath path: [Int]) -> Int {
        assert(flowRates[path.first!] == 0)
        var result = 0
        var remainingTime = 30
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
    // XXX unclear whether this is an appropriate A* heuristic
    private func residualFlowRate(opened: [Int]) -> Int {
        var result = 0
        for i in flowRates.indices {
            if !opened.contains(i) {
                result += flowRates[i]
            }
        }
        return result
    }

    // A* (mostly)
    // XXX Dijkstra's?
    func search<T: Solution>(initial: T) -> T? {
        var fringe = PriorityQueue<T>()
        fringe.push(priority: residualFlowRate(opened: initial.opened), element: initial)
        while let current = fringe.pop() {
            if current.isTerminal {
                return current
            }
            for candidate in current.neighbors(edges: edges, residualFlowRate: residualFlowRate(opened: current.opened)) {
                // Technically not admissible when no time remaining, but
                // shouldn't matter at the end of the search.
                // XXX maybe it does matter
                fringe.push(priority: candidate.cost + residualFlowRate(opened: candidate.opened), element: candidate)
            }
        }
        return nil
    }
}

protocol Solution {
    var opened: [Int] { get }
    var cost: Int { get }
    var isTerminal: Bool { get }
    func neighbors(edges: [[Int]], residualFlowRate: Int) -> [Self]
}

struct SolutionP1: Solution {
    var path: [Int]
    var remainingTime: Int
    var cost: Int

    var opened: [Int] { path }
    var isTerminal: Bool { remainingTime == 0 }

    func neighbors(edges: [[Int]], residualFlowRate: Int) -> [Self] {
        var result: [SolutionP1] = []
        for i in edges.indices {
            let transitionTime = edges[path.last!][i]
            guard !path.contains(i),  // do not revisit nodes
                  remainingTime >= transitionTime else {
                continue
            }
            result.append(SolutionP1(
                path: path + [i],
                remainingTime: remainingTime - transitionTime,
                cost: cost + transitionTime * residualFlowRate))
        }
        result.append(SolutionP1(path: path, remainingTime: 0, cost: cost + remainingTime * residualFlowRate))
        return result
    }
}

extension [Int]: Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        if lhs.count == rhs.count {
            for i in lhs.indices {
                if lhs[i] < rhs[i] {
                    return true
                } else if lhs[i] > rhs[i] {
                    return false
                }
            }
            return false
        } else {
            return lhs.count < rhs.count
        }
    }
}

// XXX should be permutations
func combinations(_ base: some Collection<Int>, count: Int) -> [[Int]] {
    if base.count < count {
        return []
    }
    let head = base[base.startIndex]
    let tail = base.dropFirst()
    return combinations(tail, count: count - 1).map({ [head] + $0 }) + combinations(tail, count: count)
}

// XXX route
struct SolutionP2: Solution {
    var paths: [[Int]]
    var cost: Int

    static let totalTime: Int = 26

    var opened: [Int] { paths.reduce(into: [], { $0 += $1 }) }
    var isTerminal: Bool { paths.filter({ $0.last! != -1 }).isEmpty }

    func neighbors(edges: [[Int]], residualFlowRate: Int) -> [Self] {
        let elapsed = paths.map { path in
            zip(path, path.dropFirst()).map({ edges[$0][$1] }).reduce(0, +)
        }
        let maxElapsed = elapsed.max()!

        var result: [SolutionP2] = []
        // XXX -1 only works for n == 2
        outer: for append in combinations(-1 ..< edges.count, count: paths.count) {
            var newPaths = paths
            var newElapsed = elapsed
            var newMaxElapsed: Int? = nil
            for i in paths.indices {
                // XXX cost
                if append[i] > -1 {
                    newElapsed[i] += edges[paths[i].last!][i]
                    if newMaxElapsed == nil {
                        newMaxElapsed = newElapsed[i]
                    }
                    guard !opened.contains(i),  // do not revisit nodes
                            newMaxElapsed! <= Self.totalTime,
                            newElapsed[i] == newMaxElapsed,
                            newMaxElapsed! > maxElapsed else {
                        continue outer
                    }
                    newPaths[i].append(append[i])
                }
            }
            newPaths.sort(by: <)
            result.append(SolutionP2(
                paths: newPaths,
                cost: cost + (newMaxElapsed! - maxElapsed) * residualFlowRate))
        }
        if result.isEmpty {  // terminal node
            let newPaths = paths.map({ $0 + [-1] })
            result.append(SolutionP2(
                paths: newPaths,
                cost: cost + (Self.totalTime - maxElapsed) * residualFlowRate))
        }
        return result
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

let p1 = graph.search(initial: SolutionP1(path: [start], remainingTime: 30, cost: 0))!
print(graph.pressure(ofPath: p1.path))

let p2 = graph.search(initial: SolutionP2(paths: [[start], [start]], cost: 0))!
print(p2.paths.map({ $0.dropLast().map({ graph.names[$0] }) }))
