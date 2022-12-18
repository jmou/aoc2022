typealias Pos = Int

struct Map {
    var elevations: [Int]
    var width: Int
    var start: Pos
    var end: Pos

    func neighbors(of pos: Pos) -> [Pos] {
        precondition(pos >= 0)
        precondition(pos < elevations.count)
        var result: [Pos] = []
        if pos > width {
            result.append(pos - width)
        }
        if pos + width < elevations.count {
            result.append(pos + width)
        }
        let column = pos % width
        if column < width - 1 {
            result.append(pos + 1)
        }
        if column > 0 {
            result.append(pos - 1)
        }
        return result
    }
}

struct Search {
    var map: Map
    var visited: [Bool]
    var p2: Int? = nil

    init(map: Map) {
        self.map = map
        self.visited = Array(repeating: false, count: map.elevations.count)
    }

    mutating func bfs() -> Int {
        // Actually search from end to start (to facilitate part 2)
        var queue = [(0, map.end)]
        repeat {
            let (cost, pos) = queue.removeFirst()
            if p2 == nil && map.elevations[pos] == 0 {
                p2 = cost
            }
            if pos == map.start {
                return cost
            } else if visited[pos] {  // already visited a shorter path
                continue
            }
            visited[pos] = true
            let horizon = map.neighbors(of: pos).filter {
                !visited[$0] && map.elevations[pos] <= map.elevations[$0] + 1
            }
            queue += horizon.map({ (cost + 1, $0) })
        } while !queue.isEmpty
        fatalError("no path")
    }
}

var start: Int? = nil
var end: Int? = nil
var width: Int? = nil
var elevations: [Int] = []
while let line = readLine() {
    for var char in line {
        if char == "S" {
            precondition(start == nil)
            start = elevations.count
            char = "a"
        } else if char == "E" {
            precondition(end == nil)
            end = elevations.count
            char = "z"
        }
        precondition(char >= "a")
        precondition(char <= "z")
        let elevation = char.asciiValue! - UInt8(ascii: "a")
        elevations.append(Int(elevation))
    }
    if let width {
        precondition(elevations.count.isMultiple(of: width))
    } else {
        width = elevations.count
    }
}
let map = Map(elevations: elevations, width: width!, start: start!, end: end!)
var search = Search(map: map)

print(search.bfs())
print(search.p2!)
