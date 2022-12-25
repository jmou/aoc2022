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

enum Direction: Character, CaseIterable {
    case up = "^"
    case right = ">"
    case down = "v"
    case left = "<"
}

struct Point : Hashable {
    var x: Int
    var y: Int

    func manhattanDistance(_ other: Point) -> Int {
        return abs(other.x - x) + abs(other.y - y)
    }

    func neighbor(to direction: Direction) -> Point {
        switch direction {
        case .up:
            return Point(x: x, y: y - 1)
        case .right:
            return Point(x: x + 1, y: y)
        case .down:
            return Point(x: x, y: y + 1)
        case .left:
            return Point(x: x - 1, y: y)
        }
    }

    func wrap(xRange: ClosedRange<Int>, yRange: ClosedRange<Int>) -> Point {
        var point = self
        while point.x < xRange.lowerBound {
            point.x += xRange.count
        }
        while point.x > xRange.upperBound {
            point.x -= xRange.count
        }
        while point.y < yRange.lowerBound {
            point.y += yRange.count
        }
        while point.y > yRange.upperBound {
            point.y -= yRange.count
        }
        return point
    }
}

struct Blizzards {
    typealias State = [Point: [Direction]]

    var states: [State]
    var xRange: ClosedRange<Int>
    var yRange: ClosedRange<Int>

    init(initial: State) {
        self.states = [initial]
        // Assumes blizzards are at input extents.
        self.xRange = initial.keys.map(\.x).min()! ... initial.keys.map(\.x).max()!
        self.yRange = initial.keys.map(\.y).min()! ... initial.keys.map(\.y).max()!

        while states.count < xRange.count * yRange.count {  // GCD would be slightly more efficient
            var state: State = [:]
            for (point, directions) in states.last! {
                for direction in directions {
                    let next = point.neighbor(to: direction).wrap(xRange: xRange, yRange: yRange)
                    state[next, default: []].append(direction)
                }
            }
            states.append(state)
        }
    }

    mutating func filterAvailable(points: [Point], at time: Int) -> [Point] {
        let state = states[time % states.count]
        return points.filter({ state[$0] == nil })
    }

    private func printDebug(_ state: State) {
        for y in yRange {
            print(xRange.map { x in 
                let directions = state[Point(x: x, y: y)]
                if let directions {
                    return directions.count == 1 ? String(directions[0].rawValue) : String(directions.count)
                } else {
                    return "."
                }
            }.joined())
        }
        print()
    }
}

struct Valley {
    var start: Point
    var end: Point
    var walls: Set<Point>
    var blizzards: Blizzards

    struct State : Hashable {
        var time: Int
        var pos: Point
        var pass: Int  // 2: to end, 1: to start, 0: to end
    }

    private func heuristicPriorityPush(fringe: inout PriorityQueue<State>, state: State) {
        let target = state.pass.isMultiple(of: 2) ? start : end
        let roundtripsDistance = (state.pass - 1) * start.manhattanDistance(end)
        fringe.push(priority: state.time + roundtripsDistance + state.pos.manhattanDistance(target), element: state)
    }

    mutating func search(passes: Int) -> Int {  // A*
        var fringe = PriorityQueue<State>()
        var visited: Set<State> = []
        heuristicPriorityPush(fringe: &fringe, state: State(time: 0, pos: start, pass: passes))
        while let state = fringe.pop() {
            guard visited.insert(state).inserted else {
                continue
            }
            var pass = state.pass
            if state.pos == (state.pass.isMultiple(of: 2) ? start : end) {
                pass -= 1
            }
            if pass == 0 {
                return state.time
            }
            let neighbors = Direction.allCases.map(state.pos.neighbor).filter({ !walls.contains($0) }) + [state.pos]
            let candidates = blizzards.filterAvailable(points: neighbors, at: state.time + 1)
            for nextPos in candidates {
                heuristicPriorityPush(fringe: &fringe, state: State(time: state.time + 1, pos: nextPos, pass: pass))
            }
        }
        fatalError("path not found")
    }
}

var openings: [Point] = []
var walls: Set<Point> = []
var blizzards: [Point: [Direction]] = [:]
var y = 0
while let line = readLine() {
    let hasOpening = line.filter({ $0 != "#" }) == ["."]
    for (x, character) in line.enumerated() {
        let point = Point(x: x, y: y)
        switch character {
        case "#":
            walls.insert(point)
        case ".":
            if hasOpening {
                openings.append(point)
            }
        case "^", ">", "v", "<":
            blizzards[point] = [Direction(rawValue: character)!]
        default:
            fatalError()
        }
    }
    y += 1
}
precondition(openings.count == 2)
walls.insert(openings[0].neighbor(to: .up))

var valley = Valley(start: openings[0], end: openings[1], walls: walls, blizzards: Blizzards(initial: blizzards))
print(valley.search(passes: 1))
print(valley.search(passes: 3))
