struct Point: Hashable {
    var x: Int = 0
    var y: Int = 0
}

struct Delta {
    var dx: Int = 0
    var dy: Int = 0
}

func +(lhs: Point, rhs: Delta) -> Point {
    return Point(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
}

func +=(lhs: inout Point, rhs: Delta) {
    lhs = lhs + rhs
}

func -(lhs: Point, rhs: Point) -> Delta {
    return Delta(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
}

struct Rope {
    var knots: [Point] = Array(repeating: Point(), count: 10)

    private mutating func updatePosition(pos: Int) {
        var delta = knots[pos] - knots[pos - 1]
        if abs(delta.dx) > abs(delta.dy) {
            delta.dy = 0
        } else if abs(delta.dx) < abs(delta.dy) {
            delta.dx = 0
        }
        delta.dx = min(max(delta.dx, -1), 1)
        delta.dy = min(max(delta.dy, -1), 1)
        knots[pos] = knots[pos - 1] + delta
    }

    mutating func update(delta: Delta) {
        knots[0] += delta
        for pos in 1..<10 {
            updatePosition(pos: pos)
        }
    }
}

var rope = Rope()
var p1 = Set([rope.knots[1]])
var p2 = Set([rope.knots[9]])
while let line = readLine() {
    let pieces = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
    guard let count = Int(pieces[1]) else {
        fatalError("bad count")
    }
    var delta: Delta
    switch pieces[0] {
    case "U":
        delta = Delta(dx: 0, dy: 1)
    case "R":
        delta = Delta(dx: 1, dy: 0)
    case "D":
        delta = Delta(dx: 0, dy: -1)
    case "L":
        delta = Delta(dx: -1, dy: 0)
    default:
        fatalError("bad direction")
    }

    for _ in 0..<count {
        rope.update(delta: delta)
        p1.insert(rope.knots[1])
        p2.insert(rope.knots[9])
    }
}

print(p1.count)
print(p2.count)
