extension ClosedRange {
    func includes(_ other: ClosedRange) -> Bool {
        return self.lowerBound <= other.lowerBound && self.upperBound >= other.upperBound
    }
}

func parseRange(_ range: any StringProtocol) -> ClosedRange<Int> {
    let pieces = range.split(separator: "-", maxSplits: 1).map({ Int($0)! })
    return pieces[0]...pieces[1]
}

var contained = 0
var overlapped = 0
while let line = readLine() {
    let pair = line.split(separator: ",", maxSplits: 1).map(parseRange)
    if pair[0].includes(pair[1]) || pair[1].includes(pair[0]) {
        contained += 1
    }
    if pair[0].overlaps(pair[1]) {
        overlapped += 1
    }
}
print(contained)
print(overlapped)
