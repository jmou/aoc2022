// Foundation also has ComparisonResult.
enum Comparison: Int {
    case less = 0, equal = 1, greater = 2
    func inverted() -> Comparison {
        Comparison(rawValue: 2 - rawValue)!
    }
}

// Questionable use of dynamic typing (as opposed to enum).
protocol MyComparable {
    func compare(to other: any MyComparable) -> Comparison
}

extension Int: MyComparable {
    func compare(to other: any MyComparable) -> Comparison {
        if let other = other as? Int {
            if self < other {
                return .less
            } else if self > other {
                return .greater
            } else {
                return .equal
            }
        } else if let other = other as? [MyComparable] {
            return other.compare(to: self).inverted()
        } else {
            fatalError("can't compare type")
        }
    }
}

extension [MyComparable]: MyComparable {
    func compare(to other: any MyComparable) -> Comparison {
        if let other = other as? [MyComparable] {
            for (left, right) in zip(self, other) {
                let comparison = left.compare(to: right)
                if comparison != .equal {
                    return comparison
                }
            }
            return self.count.compare(to: other.count)
        } else if let other = other as? Int {
            return compare(to: [other])
        } else {
            fatalError("can't compare type")
        }
    }
}

extension Substring {
    func parseLiteral(_ prefix: some StringProtocol) -> Substring? {
        return starts(with: prefix) ? dropFirst(prefix.count) : nil
    }

    func parseInt() -> (Substring, Int)? {
        // isNumber includes non-ASCII numbers.
        let number = prefix { $0.isASCII && $0.isNumber }
        guard !number.isEmpty else {
            return nil
        }
        return (dropFirst(number.count), Int(number)!)
    }

    func parseArray() -> (Substring, [MyComparable])? {
        guard var s = parseLiteral("[") else {
            return nil
        }
        if let s = s.parseLiteral("]") {
            return (s, [])
        }
        var result: [MyComparable] = []
        while true {
            guard let (newS, element) = s.parseExpression() else {
                fatalError("invalid array element")
            }
            s = newS
            result.append(element)
            if let newS = s.parseLiteral(",") {
                s = newS
                continue
            } else if let s = s.parseLiteral("]") {
                return (s, result)
            }
            fatalError("invalid array delimiter")
        }
    }

    func parseExpression() -> (Substring, MyComparable)? {
        if let result = parseInt() {
            return result
        } else if let result = parseArray() {
            return result
        }
        return nil
    }
}

func parse(_ input: String) -> any MyComparable {
    guard let (s, expression) = Substring(input).parseExpression() else {
        fatalError("invalid expression")
    }
    guard s.isEmpty else {
        fatalError("residual input")
    }
    return expression
}

var lesser: [Int] = []
var packets: [MyComparable] = []
while let line = readLine() {
    packets.append(parse(line))
    if !packets.isEmpty && packets.count.isMultiple(of: 2) {
        let pair = packets[packets.count - 2 ..< packets.count]
        // Indexing into slices is awkward.
        if pair[pair.startIndex].compare(to: pair[pair.index(pair.startIndex, offsetBy: 1)]) == .less {
            lesser.append(packets.count / 2)
        }
        switch readLine() {
        case nil:
            break
        case "":
            continue
        default:
            fatalError("invalid record delimiter")
        }
    }
}

print(lesser.reduce(0, +))

func isDivider(_ x: any MyComparable) -> Bool {
    guard let x = x as? [[Int]], x == [[2]] || x == [[6]] else {
        return false
    }
    return true
}

packets += [[[2]], [[6]]]
packets.sort { $0.compare(to: $1) == .less }
let dividers = packets.enumerated().flatMap { i, x in isDivider(x) ? [i + 1] : [] }
print(dividers.reduce(1, *))
