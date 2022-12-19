import Foundation

struct Point: Hashable {
    var x: Int
    var y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    init(from string: String) {
        let pieces = string.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false).map({ Int($0)! })
        self.x = pieces[0]
        self.y = pieces[1]
    }

    private static func range(_ a: Int, _ b: Int) -> some Sequence<Int> {
        return stride(from: a, through: b, by: a < b ? 1 : -1)
    }

    func through(_ other: Point) -> some Sequence<Point> {
        if x == other.x {
            return Point.range(y, other.y).map({ Point(x, $0) })
        } else {
            precondition(y == other.y)
            return Point.range(x, other.x).map({ Point($0, y) })
        }
    }

    func below() -> some Sequence<Point> {
        [0, -1, 1].lazy.map({ Point(x + $0, y + 1) })
    }
}

struct Cave {
    var occupied: Set<Point> = []
    var bottom: Int = 0

    mutating func addRocks(onPath path: [Point]) {
        for (from, to) in zip(path, path.dropFirst()) {
            for point in from.through(to) {
                occupied.insert(point)
                bottom = max(bottom, point.y)
            }
        }
    }

    mutating func addSand(withFloor: Bool) -> Bool {
        let initial = Point(500, 0)
        var sand = initial
        outer: while true {
            for next in sand.below() {
                if next.y == bottom + 2 {
                    if withFloor {
                        break
                    } else {
                        return false
                    }
                }
                if !occupied.contains(next) {
                    sand = next
                    continue outer
                }
            }
            occupied.insert(sand)
            return !withFloor || sand != initial
        }
    }
}

var cave = Cave()
while let line = readLine() {
    let path = line.components(separatedBy: " -> ").map(Point.init)
    cave.addRocks(onPath: path)
}
let rocks = cave.occupied

let bottom = cave.bottom
while cave.addSand(withFloor: false) {}
print(cave.occupied.count - rocks.count)

while cave.addSand(withFloor: true) {}
print(cave.occupied.count - rocks.count)
