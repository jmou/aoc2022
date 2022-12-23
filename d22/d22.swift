enum Action {
    case forward(Int)
    case left, right
}

enum Facing: Int, CaseIterable {
    case right = 0
    case down = 1
    case left = 2
    case up = 3

    var horizontal: Bool { self == .right || self == .left }
    var polarity: Int { rawValue < 2 ? 1 : -1 }
    var opposite: Facing { turnRight(times: 2) }

    func turnRight(times: Int) -> Facing { Facing(rawValue: (rawValue + times) % 4)! }
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

struct Segment: Hashable {  // aka cube face
    var x: Int
    var y: Int

    func neighbor(to facing: Facing) -> Segment{
        if facing.horizontal {
            return Segment(x: x + facing.polarity, y: y)
        } else {
            return Segment(x: x, y: y + facing.polarity)
        }
    }
}

struct Edge: Hashable {
    var segment: Segment
    var facing: Facing

    var reverse: Edge { Edge(segment: segment, facing: facing.opposite) }
}

struct Cube {
    var edges: [Edge: Edge]

    init(fromCubeNet segments: [Segment]) {
        precondition(segments.count == 6)
        self.edges = [:]
        for segment in segments {
            for facing in Facing.allCases {
                let edge = Edge(segment: segment, facing: facing)
                let neighbor = segment.neighbor(to: facing)
                if segments.contains(neighbor) {
                    let wrap = Edge(segment: neighbor, facing: facing)
                    self.edges[edge] = wrap
                    self.edges[wrap.reverse] = edge.reverse
                }
            }
        }
        while self.edges.count < segments.count * Facing.allCases.count {
            for segment in segments {
                for facing in Facing.allCases {
                    let edge = Edge(segment: segment, facing: facing)
                    guard self.edges[edge] == nil else { continue }
                    for turns in [1, 3] {
                        let viaFacing = facing.turnRight(times: turns)
                        let viaEdge = Edge(segment: segment, facing: viaFacing)
                        guard let viaWrap = self.edges[viaEdge],
                              let indirectWrap = self.edges[(Edge(segment: viaWrap.segment, facing: viaWrap.facing.turnRight(times: turns).opposite))] else {
                            continue
                        }
                        let wrap = Edge(segment: indirectWrap.segment, facing: indirectWrap.facing.turnRight(times: turns))
                        self.edges[edge] = wrap
                        self.edges[wrap.reverse] = edge.reverse
                    }
                }
            }
        }
        assert(self.edges.reduce(into: [:], { $0[$1.value.facing, default: 0] += 1 }).values.allSatisfy({ $0 == segments.count }))
    }

    func wrap(x: Int, y: Int, facing: Facing) -> Edge {
        return edges[Edge(segment: Segment(x: x, y: y), facing: facing)]!
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
            pos.x = map.rows[pos.y].walk(from: pos.x, by: distance * pos.facing.polarity)
        } else {
            pos.y = map.columns[pos.x].walk(from: pos.y, by: distance * pos.facing.polarity)
        }
    case .left:
        pos.facing = pos.facing.turnRight(times: 3)
    case .right:
        pos.facing = pos.facing.turnRight(times: 1)
    }
}

struct Globe {
    var map: Map
    var cube: Cube
    var segmentSize: Int

    init(fromRows rows: [Slice]) {
        self.map = Map(fromRows: rows)
        let cellCount = rows.map(\.range).map(\.count).reduce(0, +)
        self.segmentSize = Int(Double(cellCount / 6).squareRoot())
        assert(self.segmentSize * self.segmentSize * 6 == cellCount)

        var segments: [Segment] = []
        precondition(rows.count.isMultiple(of: self.segmentSize))
        for y in 0 ..< rows.count / self.segmentSize {
            let row = rows[y * self.segmentSize]
            precondition(row.range.lowerBound.isMultiple(of: self.segmentSize))
            precondition(row.range.count.isMultiple(of: self.segmentSize))
            for x in row.range.lowerBound / self.segmentSize ... row.range.upperBound / self.segmentSize {
                segments.append(Segment(x: x, y: y))
            }
        }
        precondition(segments.count == 6)
        self.cube = Cube(fromCubeNet: segments)
    }

    private func isInBounds(x: Int, y: Int) -> Bool { map.rows.indices.contains(y) && map.rows[y].range.contains(x) }
    private func isWall(x: Int, y: Int) -> Bool { map.rows[y].walls.contains(x) }

    func moveForward(from start: Position, by distance: Int) -> Position {
        assert(distance >= 0)
        var distance = distance
        var pos = start
        while distance > 0 {
            var next = Position(
                x: pos.facing.horizontal ? pos.x + pos.facing.polarity : pos.x,
                y: pos.facing.horizontal ? pos.y : pos.y + pos.facing.polarity,
                facing: pos.facing)
            if !isInBounds(x: next.x, y: next.y) {
                assert((pos.facing == .up && pos.y.isMultiple(of: segmentSize)) ||
                       (pos.facing == .right && next.x.isMultiple(of: segmentSize)) ||
                       (pos.facing == .down && next.y.isMultiple(of: segmentSize)) ||
                       (pos.facing == .left && pos.x.isMultiple(of: segmentSize)))
                let wrap = cube.wrap(x: pos.x / segmentSize, y: pos.y / segmentSize, facing: pos.facing)
                var lx = (next.x + segmentSize) % segmentSize
                var ly = (next.y + segmentSize) % segmentSize
                if wrap.facing == pos.facing {
                    // nominal orientation
                } else if wrap.facing == pos.facing.turnRight(times: 1) {
                    (lx, ly) = (segmentSize - 1 - ly, lx)
                } else if wrap.facing == pos.facing.turnRight(times: 2) {
                    (lx, ly) = (segmentSize - 1 - lx, segmentSize - 1 - ly)
                } else {
                    (lx, ly) = (ly, segmentSize - 1 - lx)
                }
                next = Position(
                    x: wrap.segment.x * segmentSize + lx,
                    y: wrap.segment.y * segmentSize + ly,
                    facing: wrap.facing)
                assert(isInBounds(x: next.x, y: next.y))
            }
            if isWall(x: next.x, y: next.y) {
                break
            }
            pos = next
            distance -= 1
        }
        return pos
    }

    func act(_ action: Action, from pos: Position) -> Position {
        switch action {
        case let .forward(distance):
            assert(distance >= 0)
            return moveForward(from: pos, by: distance)
        case .left:
            return Position(x: pos.x, y: pos.y, facing: pos.facing.turnRight(times: 3))
        case .right:
            return Position(x: pos.x, y: pos.y, facing: pos.facing.turnRight(times: 1))
        }
    }
}

enum Cell: Character {
    case void = " "
    case open = "."
    case wall = "#"
}

func main() {
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

    let globe = Globe(fromRows: rows)
    var p2 = Position(x: rows[0].range.first(where: { !rows[0].walls.contains($0) })!, y: 0, facing: .right)
    path.forEach({ action in p2 = globe.act(action, from: p2) })
    print(p2.password)
}

switch CommandLine.arguments.dropFirst() {
case []:
    main()
case ["test"]:
    // ##
    //  ###
    //   #
    let cube = Cube(fromCubeNet: [(0, 0), (1, 0), (1, 1), (2, 1), (2, 2), (3, 1)].map({ x, y in Segment(x: x, y: y) }))
    assert(cube.wrap(x: 2, y: 2, facing: .right) == Edge(segment: Segment(x: 3, y: 1), facing: .up))
    assert(cube.wrap(x: 0, y: 0, facing: .left) == Edge(segment: Segment(x: 2, y: 2), facing: .up))
default:
    fatalError()
}
