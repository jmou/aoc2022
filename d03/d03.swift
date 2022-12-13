func calculatePriority(of item: Character) -> Int {
    if item >= "a" && item <= "z" {
        return Int(item.asciiValue! - UInt8(ascii: "a")) + 1
    } else {
        assert(item >= "A" && item <= "Z")
        return Int(item.asciiValue! - UInt8(ascii: "A")) + 27
    }
}

var lines: [String] = []
while let line = readLine() {
    lines.append(line)
}

var p1 = 0
for line in lines {
    assert(line.count.isMultiple(of: 2))
    let half = line.index(line.startIndex, offsetBy: line.count / 2)
    let first = line[..<half]
    let second = line[half...]
    let intersection = Set(first).intersection(second)
    assert(intersection.count == 1)
    p1 += calculatePriority(of: intersection.first!)
}
print(p1)

var p2 = 0
for start in stride(from: 0, to: lines.count, by: 3) {
    let common = lines[start + 1..<start + 3].reduce(Set(lines[start])) { $0.intersection($1) }
    assert(common.count == 1)
    p2 += calculatePriority(of: common.first!)
}
print(p2)
