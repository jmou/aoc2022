enum Instruction {
    case addx(value: Int)
    case noop
}

struct Machine {
    var regX: Int = 1
    var clock: Int = 1
    var ip: Int = 0
    var substep: Int = 0
    var program: [Instruction]

    var running: Bool { ip < program.count }

    var signal: Int { clock * regX }

    mutating func step() {
        switch program[ip] {
        case .addx where substep == 0:
            substep += 1
        case .addx(let value) where substep == 1:
            regX += value
            ip += 1
            substep = 0
        case .noop:
            ip += 1
        default:
            fatalError("bad state")
        }
        clock += 1
    }
}

var program: [Instruction] = []
while let line = readLine() {
    let pieces = line.split(separator: " ", omittingEmptySubsequences: false)
    switch pieces[0] {
    case "noop" where pieces.count == 1:
        program.append(.noop)
    case "addx" where pieces.count == 2:
        program.append(.addx(value: Int(pieces[1])!))
    default:
        fatalError("bad instruction")
    }
}

var machine = Machine(program: program)
var sum = 0
var display: [Bool] = []
while machine.running {
    let scanX = (machine.clock - 1) % 40
    let lit = abs(scanX - machine.regX) <= 1
    display.append(lit)
    machine.step()
    if (machine.clock - 20) % 40 == 0 {
        sum += machine.signal
    }
}
print(sum)
for i in 0..<display.count {
    print(display[i] ? "#" : ".", terminator: i % 40 == 39 ? "\n" : "")
}
