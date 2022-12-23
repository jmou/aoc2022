enum Direction {
    case north, south, west, east
    var horizontal: Bool { self == .west || self == .east }
}

struct Point: Hashable {
    var x: Int
    var y: Int

    func neighbors(dx: [Int] = [-1, 0, 1], dy: [Int] = [-1, 0, 1]) -> [Point] {
        var result: [Point] = []
        for dx in dx {
            for dy in dy {
                guard dx != 0 || dy != 0 else { continue }
                result.append(Point(x: x + dx, y: y + dy))
            }
        }
        return result
    }
}

struct Grove {
    var elves: Set<Point> = []
    var directions: [Direction] = [.north, .south, .west, .east]

    mutating func step() {
        var proposals: [Point: [Point]] = [:]
        elf: for elf in elves {
            guard elf.neighbors().contains(where: elves.contains) else {
                assert(proposals[elf] == nil)
                proposals[elf] = [elf]
                continue
            }
            for direction in directions {
                let delta = direction == .south || direction == .east ? [1] : [-1]
                let neighbors = direction.horizontal ? elf.neighbors(dx: delta) : elf.neighbors(dy: delta)
                if !neighbors.contains(where: elves.contains) {
                    // Assumes middle neighbor is axis aligned.
                    proposals[neighbors[1], default: []].append(elf)
                    continue elf
                }
            }
            assert(proposals[elf] == nil)
            proposals[elf] = [elf]
        }
        for destination in proposals.keys {
            let originals = proposals[destination]!
            if originals.count > 1 {
                proposals[destination] = nil
                for original in originals {
                    assert(proposals[original] == nil)
                    proposals[original] = [original]
                }
            }
        }
        assert(proposals.count == elves.count)
        elves = Set(proposals.keys)
        directions.append(directions.removeFirst())
    }

    func vacancy() -> Int {
        let xrange = elves.map(\.x).min()! ... elves.map(\.x).max()!
        let yrange = elves.map(\.y).min()! ... elves.map(\.y).max()!
        return xrange.count * yrange.count - elves.count
    }
}

var grove = Grove()
var y = 0
while let line = readLine() {
    grove.elves.formUnion(line.enumerated().filter({ $0.element == "#" }).map({ Point(x: $0.offset, y: y) }))
    y += 1
}

for _ in 0 ..< 10 {
    grove.step()
}
print(grove.vacancy())

var i = 10
var oldElves: Set<Point>
repeat {
    oldElves = grove.elves
    grove.step()
    i += 1
} while oldElves != grove.elves
print(i)
