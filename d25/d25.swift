struct Snafu: CustomStringConvertible {
    var decimal: Int

    private static func parse(_ character: Character) -> Int? {
        switch character {
        case "-":
            return -1
        case "=":
            return -2
        default:
            return Int(String(character))
        }
    }

    init(fromDecimal decimal: Int) {
        self.decimal = decimal
    }

    init?(_ string: String) {
        var value = 0
        for digit in string.map(Snafu.parse) {
            guard let digit else { return nil }
            value = value * 5 + digit
        }
        self.decimal = value
    }

    var description: String {
        var result: [Character] = []
        var rest = decimal
        while rest != 0 {
            switch rest % 5 {
            case 0, 1, 2:
                result.append(String(rest % 5).first!)
            case 3:
                result.append("=")
                rest += 5
            case 4:
                result.append("-")
                rest += 5
            default:
                fatalError("negative value")
            }
            rest /= 5
        }
        return String(result.reversed())
    }
}

switch CommandLine.arguments.dropFirst() {
case ["test"]:
    for (decimal, snafu) in [
        (1, "1"),
        (2, "2"),
        (3, "1="),
        (4, "1-"),
        (5, "10"),
        (6, "11"),
        (7, "12"),
        (8, "2="),
        (9, "2-"),
        (10, "20"),
        (15, "1=0"),
        (20, "1-0"),
        (2022, "1=11-2"),
        (12345, "1-0---0"),
        (314159265, "1121-1110-1=0"),
    ] {
        assert(Snafu(fromDecimal: decimal).description == snafu)
        assert(Snafu(snafu)?.decimal == decimal)
    }

case []:
    var sum = 0
    while let line = readLine() {
        guard let snafu = Snafu(line) else {
            fatalError()
        }
        sum += snafu.decimal
    }
    print(Snafu(fromDecimal: sum))

default:
    fatalError()
}
