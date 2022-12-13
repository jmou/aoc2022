func calculateScore(their: UInt8, mine: UInt8) -> Int {
    let shape = Int(mine) + 1
    if their == mine {
        return shape + 3
    } else if (their + 1) % 3 == mine {
        return shape + 6
    } else {
        return shape + 0
    }
}

var p1Total = 0
var p2Total = 0
while let line = readLine() {
    let pieces = line.split(separator: " ", maxSplits: 1)
    assert(pieces[0] == "A" || pieces[0] == "B" || pieces[0] == "C")
    let their = pieces[0].first!.asciiValue! - UInt8(ascii: "A")
    assert(pieces[1] == "X" || pieces[1] == "Y" || pieces[1] == "Z")

    let mine = pieces[1].first!.asciiValue! - UInt8(ascii: "X")
    p1Total += calculateScore(their: their, mine: mine)

    // Applying the strategy is equivalent to rotating their by delta.
    let delta = mine + 2
    p2Total += calculateScore(their: their, mine: (their + delta) % 3)
}
print(p1Total)
print(p2Total)
