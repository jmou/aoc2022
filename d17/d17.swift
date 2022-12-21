// Based on https://sveinhal.github.io/2018/06/14/repeating-sequence/
struct RepeatingSequence<T: Collection>: Sequence, IteratorProtocol {
    typealias Element = T.Element
    let base: T
    var i: T.Index
    init(_ base: T) {
        self.base = base
        self.i = base.startIndex
    }
    mutating func next() -> T.Element? {
        defer {
            i = (base.index(after: i) == base.endIndex)
                ? base.startIndex : base.index(after: i)
        }
        return base[i]
    }
}

struct Point {
    var x: Int
    var y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

struct Delta {
    var dx: Int
    var dy: Int
}

func +(lhs: Point, rhs: Delta) -> Point {
    Point(lhs.x + rhs.dx, lhs.y + rhs.dy)    
}

struct Shape {
    var offsets: [Delta]

    init(_ offsets: [(dx: Int, dy: Int)]) {
        self.offsets = offsets.map({ (dx, dy) in Delta(dx: dx, dy: dy) })
    }

    func piece(at origin: Point) -> [Point] {
        return offsets.map({ origin + $0 })
    }
}

enum Jet: Character {
    case right = ">"
    case left = "<"

    var delta: Delta {
        switch self {
        case .left:
            return Delta(dx: -1, dy: 0)
        case .right:
            return Delta(dx: 1, dy: 0)
        }
    }
}

struct Row: Equatable, Hashable {
    var bits: UInt8 = 0
    subscript(_ x: Int) -> Bool {
        get {
            assert(x < 8)
            return (1 << x) & bits != 0
        }
        set {
            assert(x < 8)
            let shifted: UInt8 = 1 << x
            bits = newValue ? bits | shifted : bits & ~shifted
        }
    }
    var array: [Bool] { (0..<8).map({ self[$0] }) }
    var character: Character { Character(UnicodeScalar(bits)) }  // 8-bit unsafe
}

struct Tetris {
    // Origin in bottom left; rows grow upward. 7-cell row stored as UInt8.
    var grid: [Row] = []
    let width: Int = 7
    var height: Int { grid.count }

    subscript(_ point: Point) -> Bool {
        get {
            precondition(point.x < width)
            return point.y < height ? grid[point.y][point.x] : false
        }
        set {
            precondition(point.x < width)
            while height <= point.y {
                grid.append(Row())
            }
            assert(!grid[point.y][point.x])
            grid[point.y][point.x] = newValue
        }
    }

    private func collide(piece: [Point]) -> Bool {
        return piece.contains(where: { $0.y < 0 || $0.x < 0 || $0.x >= width || self[$0] })
    }

    mutating func spawn(shape: Shape, jets: inout some IteratorProtocol<Jet>) {
        var position = Point(2, height + 3)
        while let jet = jets.next() {
            let shifted = position + jet.delta
            if !collide(piece: shape.piece(at: shifted)) {
                position = shifted
            }
            let fallen = position + Delta(dx: 0, dy: -1)
            if collide(piece: shape.piece(at: fallen)) {
                break
            }
            position = fallen
        }
        for point in shape.piece(at: position) {
            self[point] = true
        }
    }

    func render() -> String {
        return grid.reversed().map { row in
            String(row.array.map({ Character($0 ? "#" : ".") }))
        }.joined(separator: "\n")
    }
}

var shapes = RepeatingSequence([
    Shape([(0, 0), (1, 0), (2, 0), (3, 0)]),
    Shape([(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)]),
    Shape([(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)]),
    Shape([(0, 0), (0, 1), (0, 2), (0, 3)]),
    Shape([(0, 0), (1, 0), (0, 1), (1, 1)]),
])

let input = readLine()!
var jets = RepeatingSequence(input.map({ Jet(rawValue: $0)! }))
var tetris = Tetris()
for shape in shapes.prefix(2022) {
    tetris.spawn(shape: shape, jets: &jets)
}
print(tetris.height)

struct Snapshot: Hashable {
    var jetsI: Int
    var gridTop: [Row]
}

struct Cycle {
    var height: Int
    var iterations: Int
}

jets.i = jets.base.startIndex
shapes.i = shapes.base.startIndex
tetris.grid = []
// Spawn all shapes until state snapshot repeats.
var history: [Snapshot: Cycle] = [:]
var iterations = 0
var cycle: Cycle!  // always initialized by loop below
while true {
    for shape in shapes.base {
        tetris.spawn(shape: shape, jets: &jets)
        iterations += 1
    }
    let snapshot = Snapshot(jetsI: jets.i, gridTop: tetris.grid.suffix(10))
    if let state = history[snapshot] {
        cycle = Cycle(height: tetris.height - state.height, iterations: iterations - state.iterations)
        break
    } else {
        history[snapshot] = Cycle(height: tetris.height, iterations: iterations)
    }
}

let remainder = 1000000000000 - iterations
for shape in shapes.prefix(remainder % cycle.iterations) {
    tetris.spawn(shape: shape, jets: &jets)
}
print(tetris.height + (remainder / cycle.iterations) * cycle.height)
