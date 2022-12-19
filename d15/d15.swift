// Compile with optimizations:
// $ swift -O d15.swift < input

struct Point {
    var x: Int, y: Int

    func manhattanDistance(_ other: Point) -> Int {
        abs(other.x - x) + abs(other.y - y)
    }
}

struct Reading {
    var sensor: Point
    var beacon: Point

    func vacancyRange(atY: Int, excludeBeacon: Bool = false) -> ClosedRange<Int>? {
        let halfWidth = sensor.manhattanDistance(beacon) - abs(atY - sensor.y)
        guard halfWidth >= 0 else {
            return nil
        }
        let range = sensor.x - halfWidth ... sensor.x + halfWidth
        if excludeBeacon && atY == beacon.y {
            if range.lowerBound == range.upperBound {
                assert(beacon.x == range.lowerBound)
                return nil
            } else if beacon.x == range.lowerBound {
                return range.lowerBound + 1 ... range.upperBound
            } else {
                assert(beacon.x == range.upperBound)
                return range.lowerBound ... range.upperBound - 1
            }
        } else {
            return range
        }
    }
}

extension StringProtocol {
    func dropPrefix(_ prefix: some StringProtocol) -> SubSequence? {
        return hasPrefix(prefix) ? dropFirst(prefix.count) : nil
    }

    func parseInt() -> (SubSequence, Int)? {
        let number = prefix { $0 == "-" || ($0.isASCII && $0.isNumber) }
        guard !number.isEmpty else {
            return nil
        }
        return (dropFirst(number.count), Int(number)!)
    }
}

func coalesce(ranges: inout [ClosedRange<Int>]) {
    ranges.sort(by: { ($0.lowerBound, $0.upperBound) < ($1.lowerBound, $1.upperBound) })
    var to = ranges.startIndex + 1
    for i in ranges.indices.dropFirst() {
        if ranges[to - 1].upperBound + 1 >= ranges[i].lowerBound {
            ranges[to - 1] = ranges[to - 1].lowerBound ... max(ranges[to - 1].upperBound, ranges[i].upperBound)
        } else {
            ranges[to] = ranges[i]
            to += 1
        }
    }
    ranges.removeLast(ranges.endIndex - to)
}

var readings: [Reading] = []
while let line = readLine() {
    guard let line = line.dropPrefix("Sensor at x="),
          let (line, sensorX) = line.parseInt(),
          let line = line.dropPrefix(", y="),
          let (line, sensorY) = line.parseInt(),
          let line = line.dropPrefix(": closest beacon is at x="),
          let (line, beaconX) = line.parseInt(),
          let line = line.dropPrefix(", y="),
          let (line, beaconY) = line.parseInt(),
          line.isEmpty else {
        fatalError()
    }
    let reading = Reading(sensor: Point(x: sensorX, y: sensorY), beacon: Point(x: beaconX, y: beaconY))
    readings.append(reading)
}

var ranges = readings.compactMap({ $0.vacancyRange(atY: 2000000, excludeBeacon: true) })
coalesce(ranges: &ranges)
print(ranges.map(\.count).reduce(0, +))

let bounds = 0...4000000
var found: Point? = nil
for y in bounds {
    var ranges = readings.compactMap({ $0.vacancyRange(atY: y) })
    coalesce(ranges: &ranges)
    ranges = ranges.compactMap({ $0.overlaps(bounds) ? $0.clamped(to: bounds) : nil })
    if ranges.count > 1 {
        precondition(ranges.count == 2)
        precondition(ranges[0].lowerBound == 0)
        precondition(ranges[1].upperBound == bounds.upperBound)
        precondition(ranges[0].upperBound + 2 == ranges[1].lowerBound)
        precondition(found == nil)
        found = Point(x: ranges[0].upperBound + 1, y: y)
    } else if ranges[0] != bounds {
        fatalError("unhandled edge case")
    }
}
print(found!.x * bounds.upperBound + found!.y)
