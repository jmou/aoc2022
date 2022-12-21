struct Point: Hashable {
    var x: Int
    var y: Int
    var z: Int

    var neighbors: [Point] {
        return [(-1, 0, 0), (0, -1, 0), (0, 0, -1), (1, 0, 0), (0, 1, 0), (0, 0, 1)]
            .map { (dx, dy, dz) in
                Point(x: x + dx, y: y + dy, z: z + dz)
            }
    }
}

func exterior(of points: Set<Point>) -> Int {
    return points.map { point in
        point.neighbors.filter({ !points.contains($0) }).count
    }.reduce(0, +)
}

var points: Set<Point> = []
while let line = readLine() {
    let pieces = line
        .split(separator: ",", maxSplits: 2, omittingEmptySubsequences: false)
        .map({ Int($0)! })
    points.insert(Point(x: pieces[0], y: pieces[1], z: pieces[2]))
}

print(exterior(of: points))

func getRange(_ points: Set<Point>, by: (Point) -> Int) -> ClosedRange<Int> {
    let values = points.map(by)
    return values.min()!...values.max()!
}

func extend(range: ClosedRange<Int>) -> ClosedRange<Int> {
    return range.lowerBound - 1 ... range.upperBound + 1
}

func box(points: inout Set<Point>, xRange: ClosedRange<Int>, yRange: ClosedRange<Int>, zRange: ClosedRange<Int>) {
    let xRange = extend(range: xRange)
    let yRange = extend(range: yRange)
    let zRange = extend(range: zRange)
    for y in yRange {
        for z in zRange {
            points.insert(Point(x: xRange.lowerBound, y: y, z: z))
            points.insert(Point(x: xRange.upperBound, y: y, z: z))
        }
    }
    for x in yRange {
        for z in zRange {
            points.insert(Point(x: x, y: yRange.lowerBound, z: z))
            points.insert(Point(x: x, y: yRange.upperBound, z: z))
        }
    }
    for x in yRange {
        for y in zRange {
            points.insert(Point(x: x, y: y, z: zRange.lowerBound))
            points.insert(Point(x: x, y: y, z: zRange.upperBound))
        }
    }
}

func fill(points: inout Set<Point>, from base: Point) {
    guard !points.contains(base) else {
        return
    }
    points.insert(base)
    for neighbor in base.neighbors {
        fill(points: &points, from: neighbor)
    }
}

let xRange = extend(range: getRange(points, by: \.x))
let yRange = extend(range: getRange(points, by: \.y))
let zRange = extend(range: getRange(points, by: \.z))
var steam = points
box(points: &steam, xRange: xRange, yRange: yRange, zRange: zRange)
fill(points: &steam, from: Point(x: xRange.lowerBound, y: yRange.lowerBound, z: zRange.lowerBound))
for x in xRange {
    for y in yRange {
        for z in zRange {
            let point = Point(x: x, y: y, z: z)
            if !steam.contains(point) {
                points.insert(point)
            }
        }
    }
}
print(exterior(of: points))
