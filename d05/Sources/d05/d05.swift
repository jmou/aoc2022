import Algorithms

struct StdinIterator : Sequence, IteratorProtocol {
    typealias Element = String

    mutating func next() -> String? {
        return readLine()
    }
}

typealias Stacks = [[Character]]

struct Step {
    var count: Int
    var from: Int
    var to: Int
}

struct Input {
    var stacks: Stacks
    var steps: [Step]

    init<S: StringProtocol, T: Sequence<S>>(fromLines input: T) {
        var iterator = input.makeIterator()
        self.stacks = []
        while let line = iterator.next() {
            if line.isEmpty {
                break
            }

            for (stackIndex, token) in line.chunks(ofCount: 4).map(Array.init).enumerated() {
                while stackIndex + 1 > stacks.count {
                    self.stacks.append([])
                }
                precondition(token.count == 3 || token.count == 4)

                let symbol = token[1]
                switch Array(token) {
                case ["[", symbol, "]"],  ["[", symbol, "]", " "]:
                    self.stacks[stackIndex].append(symbol)
                case [" ", " ", " "],  [" ", " ", " ", " "]:
                    precondition(self.stacks[stackIndex].isEmpty)
                case [" ", symbol, " "],  [" ", symbol, " ", " "]:
                    precondition(Int(String(symbol)) == stackIndex + 1)
                default:
                    preconditionFailure()
                }
            }
        }
        for i in stacks.indices {
            self.stacks[i].reverse()
        }

        self.steps = []
        while let line = iterator.next() {
            let pieces = line.split(separator: " ", maxSplits: 5, omittingEmptySubsequences: false)
            precondition(pieces[0] == "move")
            precondition(pieces[2] == "from")
            precondition(pieces[4] == "to")
            steps.append(Step(count: Int(pieces[1])!, from: Int(pieces[3])! - 1, to: Int(pieces[5])! - 1))
        }
    }
}

extension Stacks {
    mutating func applyP1(steps: [Step]) {
        for step in steps {
            for _ in 0..<step.count {
                self[step.to].append(self[step.from].removeLast())
            }
        }
    }

    mutating func applyP2(steps: [Step]) {
        for step in steps {
            self[step.to] += self[step.from].suffix(step.count)
            self[step.from].removeLast(step.count)
        }
    }

    var tops: String {
        String(self.map(\.last!))
    }
}

@main
public struct d05 {
    public static func main() {
        let input = Input(fromLines: StdinIterator())
        var stacks = input.stacks
        stacks.applyP1(steps: input.steps)
        print(stacks.tops)

        stacks = input.stacks
        stacks.applyP2(steps: input.steps)
        print(stacks.tops)
    }
}
