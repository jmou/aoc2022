struct StdinParagraphs: Sequence, IteratorProtocol {
    var lines: [String]? = []
    mutating func next() -> [String]? {
        while true {
            let line = readLine()
            guard let line, line != "" else {
                let result = lines
                lines = nil
                return result
            }
            if lines == nil {
                lines = []
            }
            lines!.append(line)
        }
    }
}

typealias Worry = Int
typealias MonkeyId = Int

struct Monkey {
    var items: [Worry]
    var operation: (Worry) -> Worry
    var divisor: Int
    var divisibleTo: MonkeyId
    var indivisibleTo: MonkeyId
    var inspections: Int = 0
}

struct Game {
    var monkeys: [Monkey]
    var worryLessener: Int = 3

    // Technically misnomer (unless divisors are coprime).
    var gcd: Int {
        monkeys.map(\.divisor).reduce(1, *)
    }

    var monkeyBusiness: Int {
        var inspections = monkeys.map(\.inspections)
        inspections.sort(by: >)
        return inspections[0] * inspections[1]
    }

    mutating func step() {
        // mutating arrays while iterating is confusing. Can't seem to use
        // for-in (mutations are not visible). indices are not recommended:
        // https://developer.apple.com/documentation/swift/string/indices-swift.property
        for id in monkeys.indices {
            let monkey = monkeys[id]
            for item in monkey.items {
                let worry = monkey.operation(item) / worryLessener
                let target = worry.isMultiple(of: monkey.divisor) ? monkey.divisibleTo : monkey.indivisibleTo
                monkeys[target].items.append(worry % gcd)
            }
            monkeys[id].inspections += monkey.items.count
            monkeys[id].items.removeAll()
        }
    }
}

extension StringProtocol {
    func removePrefix(_ prefix: String) -> some StringProtocol {
        precondition(self.starts(with: prefix))
        return self.dropFirst(prefix.count)
    }
}

var monkeys: [Monkey] = []
for (i, lines) in StdinParagraphs().enumerated() {
    precondition(lines.count == 6)
    precondition(lines[0] == "Monkey \(i):")
    let items = lines[1]
        .removePrefix("  Starting items:")
        .split(separator: ",", omittingEmptySubsequences: false)
        .map { Worry($0.removePrefix(" "))! }
    let opPieces = lines[2]
        .removePrefix("  Operation: new = old ")
        .split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
    let operand = Int(opPieces[1])
    var operation: (Worry) -> Worry
    switch opPieces[0] {
    case "+":
        operation = { $0 + operand! }
    case "*" where opPieces[1] == "old":
        operation = { $0 * $0 }
    case "*":
        operation = { $0 * operand! }
    default:
        fatalError()
    }
    let divisor = Int(lines[3].removePrefix("  Test: divisible by "))!
    let divisibleTo = MonkeyId(lines[4].removePrefix("    If true: throw to monkey "))!
    precondition(divisibleTo != i)
    let indivisibleTo = MonkeyId(lines[5].removePrefix("    If false: throw to monkey "))!
    precondition(indivisibleTo != i)
    let monkey = Monkey(items: items, operation: operation, divisor: divisor, divisibleTo: divisibleTo, indivisibleTo: indivisibleTo)
    monkeys.append(monkey)
}

var game = Game(monkeys: monkeys)
for _ in 0..<20 {
    game.step()
}
print(game.monkeyBusiness)

game.monkeys = monkeys  // reset
game.worryLessener = 1
for _ in 0..<10000 {
    game.step()
}
print(game.monkeyBusiness)
