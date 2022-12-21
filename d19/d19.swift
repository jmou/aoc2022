enum Material: Int {
    case ore = 0, clay, obsidian, geode
}

typealias Requirement = [Int]

struct Blueprint {
    var id: Int
    var requirements: [Requirement]

    func maxGeodes(time: Int) -> Int {
        var simulation = Simulation(blueprint: self)
        return simulation.simulate(supply: [0, 0, 0, 0], robots: [1, 0, 0, 0], time: time)
    }
}

struct Simulation {
    var requirements: [Requirement]
    var globalMaxGeodes: Int = 0

    init(blueprint: Blueprint) {
        self.requirements = blueprint.requirements
    }

    var maxRequirements: [Int] {
        requirements[0].indices.map { i in
            requirements.map({ $0[i] }).max()!
        }
    }

    mutating func simulate(supply: [Int], robots: [Int], time: Int) -> Int {
        // Geodes produced if we idle.
        var maxGeodes = supply[Material.geode.rawValue] + time * robots[Material.geode.rawValue]
        // Prune if we cannot optimistically produce more than the high watermark.
        if maxGeodes + max(time - 1, 0) * time / 2 < globalMaxGeodes {
            return 0
        }
        if time == 1 { return maxGeodes }  // no new robots will produce materials
        // Try producing each robot.
        outer: for i in requirements.indices.reversed() {
            guard zip(requirements[i], robots).allSatisfy({ $0 == 0 || $1 > 0 }),  // no indirect production
                  Material(rawValue: i) == .geode || robots[i] + 1 <= maxRequirements[i] else {  // no excess robots
                continue
            }
            var oldSupply: [Int]
            var newSupply: [Int] = supply
            var elapsed = 0
            repeat {
                oldSupply = newSupply
                newSupply = zip(newSupply, robots).map(+)
                elapsed += 1
                guard elapsed <= time else { continue outer }
            } while zip(oldSupply, requirements[i]).contains(where: <)
            newSupply = zip(newSupply, requirements[i]).map(-)
            var newRobots = robots
            newRobots[i] += 1
            maxGeodes = max(maxGeodes, simulate(supply: newSupply, robots: newRobots, time: time - elapsed))
        }
        globalMaxGeodes = max(globalMaxGeodes, maxGeodes)
        return maxGeodes
    }
}

extension StringProtocol {
    func dropPrefix(_ prefix: some StringProtocol) -> SubSequence? {
        if hasPrefix(prefix) {
            return dropFirst(prefix.count)
        }
        return nil
    }

    func dropWhitespace() -> SubSequence? {
        // A more correct implementation should return nil if there is no whitespace.
        return drop(while: { $0.isWhitespace })
    }

    func parseInt() -> (SubSequence, Int)? {
        let parsed = prefix(while: { "0123456789".contains($0) })
        guard !parsed.isEmpty else {
            return nil
        }
        return (dropFirst(parsed.count), Int(parsed)!)
    }
}

var input = ""
while let line = readLine(strippingNewline: false) {
    input += line
}

var cursor = Substring(input)
var blueprints: [Blueprint] = []
while let buf = cursor.dropPrefix("Blueprint ") {
    guard let (buf, id) = buf.parseInt(),
          let buf = buf.dropPrefix(":"),
          let buf = buf.dropWhitespace(),
          let buf = buf.dropPrefix("Each ore robot costs "),
          let (buf, oreOre) = buf.parseInt(),
          let buf = buf.dropPrefix(" ore."),
          let buf = buf.dropWhitespace(),
          let buf = buf.dropPrefix("Each clay robot costs "),
          let (buf, clayOre) = buf.parseInt(),
          let buf = buf.dropPrefix(" ore."),
          let buf = buf.dropWhitespace(),
          let buf = buf.dropPrefix("Each obsidian robot costs "),
          let (buf, obsidianOre) = buf.parseInt(),
          let buf = buf.dropPrefix(" ore and "),
          let (buf, obsidianClay) = buf.parseInt(),
          let buf = buf.dropPrefix(" clay."),
          let buf = buf.dropWhitespace(),
          let buf = buf.dropPrefix("Each geode robot costs "),
          let (buf, geodeOre) = buf.parseInt(),
          let buf = buf.dropPrefix(" ore and "),
          let (buf, geodeObsidian) = buf.parseInt(),
          let buf = buf.dropPrefix(" obsidian."),
          let buf = buf.dropWhitespace() else {
        fatalError()
    }
    let requirements = [
        [oreOre, 0, 0, 0],  // ore
        [clayOre, 0, 0, 0],  // clay
        [obsidianOre, obsidianClay, 0, 0],  // obsidian
        [geodeOre, 0, geodeObsidian, 0],  // geode
    ]
    blueprints.append(Blueprint(id: id, requirements: requirements))
    cursor = buf
}

print(blueprints.map({ $0.id * $0.maxGeodes(time: 24) }).reduce(0, +))
print(blueprints.prefix(3).map({ $0.maxGeodes(time: 32) }).reduce(1, *))
