enum Action {
    case forward(Int)
    case left, right
}

enum Facing: Int {
    case right = 0
    case down = 1
    case left = 2
    case up = 3

    var left: Facing { Facing(rawValue: (rawValue + 3) % 4)! }
    var right: Facing { Facing(rawValue: (rawValue + 1) % 4)! }
    var horizontal: Bool { self == .right || self == .left }
    var axisMultiplier: Int { rawValue < 2 ? 1 : -1 }
}

struct Position {
    var x: Int
    var y: Int
    var facing: Facing

    var password: Int { 1000 * (y + 1) + 4 * (x + 1) + facing.rawValue }
}

struct Slice {
    var range: ClosedRange<Int>
    var walls: [Int]

    func walk(from start: Int, by distance: Int) -> Int {
        assert(range.contains(start))
        // parameters cannot be var, so need to be redeclared to modify.
        let distance = walls.isEmpty ? distance % range.count : distance
        var pos = start
        for _ in 0 ..< abs(distance) {
            var next = pos + (distance > 0 ? 1 : -1)
            if !range.contains(next) {
                next = distance > 0 ? range.lowerBound : range.upperBound
            }
            if walls.contains(next) {
                break
            }
            pos = next
        }
        return pos
    }
}

struct Map {
    var rows: [Slice]
    var columns: [Slice]

    init(fromRows rows: [Slice]) {
        self.rows = rows
        self.columns = []
        let maxColumn = rows.map(\.range).map(\.upperBound).max()!
        for i in 0 ... maxColumn {
            let start = rows.firstIndex(where: { $0.range.contains(i) })!
            // Somewhat confusingly, firstIndex returns the index into the full
            // array, not the dropFirst array slice.
            let end = rows.dropFirst(start).firstIndex(where: { !$0.range.contains(i) }) ?? rows.count
            precondition(rows.dropFirst(end).allSatisfy({ !$0.range.contains(i) }))
            let walls = rows.enumerated().filter({ $0.element.walls.contains(i) }).map(\.offset)
            precondition(walls.allSatisfy((start ..< end).contains))
            self.columns.append(Slice(range: start ... end - 1, walls: walls))
        }
    }
}

func act(_ action: Action, from pos: inout Position, in map: Map) {
    switch action {
    case let .forward(distance):
        assert(distance >= 0)
        if pos.facing.horizontal {
            pos.x = map.rows[pos.y].walk(from: pos.x, by: distance * pos.facing.axisMultiplier)
        } else {
            pos.y = map.columns[pos.x].walk(from: pos.y, by: distance * pos.facing.axisMultiplier)
        }
    case .left:
        pos.facing = pos.facing.left
    case .right:
        pos.facing = pos.facing.right
    }
}

enum Cell: Character {
    case void = " "
    case open = "."
    case wall = "#"
}

var rows: [Slice] = []
while let line = readLine(), line != "" {
    let row = line.map({ Cell(rawValue: $0)! }).enumerated()
    let bounds = row.filter({ $0.element != .void }).map(\.offset)
    let range = bounds.min()! ... bounds.max()!
    precondition(!row.contains(where: { $0.element == .void && range.contains($0.offset) }))
    let walls = row.filter({ $0.element == .wall }).map(\.offset)
    rows.append(Slice(range: range, walls: walls))
}
let map = Map(fromRows: rows)
var path: [Action] = []
var buffer = ""
for character in readLine()! {
    var flush: Action? = nil
    switch character {
    case "L":
        flush = .left
    case "R":
        flush = .right
    case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
        buffer.append(character)
    default:
        fatalError()
    }
    if let flush {
        if !buffer.isEmpty {
            path.append(.forward(Int(buffer)!))
        }
        path.append(flush)
        buffer = ""
    }
}
if !buffer.isEmpty {
    path.append(.forward(Int(buffer)!))
}
precondition(readLine() == nil)

var position = Position(x: rows[0].range.first(where: { !rows[0].walls.contains($0) })!, y: 0, facing: .right)
path.forEach({ action in act(action, from: &position, in: map) })
print(position.password)
