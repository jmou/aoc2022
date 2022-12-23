import Foundation

enum Operator: Character {
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case equals = "="
}

// Probably could have folded into a single Expression type by placing .monkey
// Expression in .op
enum InputExpression {
    case monkey(String)
    case number(Int)
    case op(String, Operator, String)
    case variable
}

enum ReducedExpression {
    case number(Int)
    indirect case op(ReducedExpression, Operator, ReducedExpression)
    case variable

    func solve(to: Int? = nil) -> Int {
        switch self {
        case let .number(number):
            assert(to == nil || to == number)
            return number
        case .op(.number, _, .number):
            fatalError("unreduced expression")
        case let .op(.number(number), .add, free),
                let .op(free, .add, .number(number)):
            return free.solve(to: to! - number)
        case let .op(.number(number), .subtract, free):
            return free.solve(to: number - to!)
        case let .op(free, .subtract, .number(number)):
            return free.solve(to: to! + number)
        case let .op(.number(number), .multiply, free),
                let .op(free, .multiply, .number(number)):
            assert(to!.isMultiple(of: number))
            return free.solve(to: to! / number)
        case let .op(.number(number), .divide, free):
            assert(number.isMultiple(of: to!))
            return free.solve(to: number / to!)
        case let .op(free, .divide, .number(number)):
            return free.solve(to: to! * number)
        case let .op(.number(number), .equals, free),
                let .op(free, .equals, .number(number)):
            assert(to == nil)
            return free.solve(to: number)
        case .variable:
            return to!
        case .op(.op, _, .op), .op(.op, _, .variable), .op(.variable, _, .op), .op(.variable, _, .variable):
            fatalError("ambiguous variable")
        }
    }
}

struct Calculator {
    var monkeys: [String: InputExpression]

    func reduce(_ expression: InputExpression) -> ReducedExpression {
        switch expression {
        case let .monkey(monkey):
            return reduce(monkeys[monkey]!)
        case let .number(number):
            return .number(number)
        case let .op(lhs, op, rhs):
            let lhs = reduce(.monkey(lhs))
            let rhs = reduce(.monkey(rhs))
            switch (lhs, op, rhs) {
            case let (.number(lhs), .add, .number(rhs)):
                return .number(lhs + rhs)
            case let (.number(lhs), .subtract, .number(rhs)):
                return .number(lhs - rhs)
            case let (.number(lhs), .multiply, .number(rhs)):
                return .number(lhs * rhs)
            case let (.number(lhs), .divide, .number(rhs)):
                return .number(lhs / rhs)
            default:
                return .op(lhs, op, rhs)
            }
        case .variable:
            return .variable
        }
    }
}

var monkeys: [String: InputExpression] = [:]
while let line = readLine() {
    let pieces = line.components(separatedBy: ": ")
    precondition(pieces.count == 2)
    var expression: InputExpression
    if let number = Int(pieces[1]) {
        expression = .number(number)
    } else {
        let subpieces = pieces[1].split(separator: " ", maxSplits: 2, omittingEmptySubsequences: false)
        precondition(subpieces[1].count == 1)
        expression = .op(String(subpieces[0]), Operator(rawValue: subpieces[1].first!)!, String(subpieces[2]))
    }
    monkeys[pieces[0]] = expression
}

var calculator = Calculator(monkeys: monkeys)
print(calculator.reduce(.monkey("root")).solve())

guard case let .op(rootLhs, _, rootRhs) = calculator.monkeys["root"] else {
    fatalError()
}
calculator.monkeys["root"] = .op(rootLhs, .equals, rootRhs)
calculator.monkeys["humn"] = .variable
print(calculator.reduce(.monkey("root")).solve())
