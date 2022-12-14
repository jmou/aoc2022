struct ParseError: Error { }

struct File {
    var name: String
    var size: Int
}

class Directory {
    // Classes do not automatically include an initializer.
    var dirs: [String: Directory] = [:]
    var files: [File] = []

    var size: Int {
        let filesSize = files.map(\.size).reduce(0, +)
        return dirs.map(\.value.size).reduce(filesSize, +)
    }

    func reduceDirs<Result>(_ initialResult: Result, _ nextPartialResult: (_ partialResult: Result, Directory) -> Result) -> Result {
        var result = initialResult
        for (_, dir) in dirs {
            result = nextPartialResult(result, dir)
            result = dir.reduceDirs(result, nextPartialResult)
        }
        return result
    }
}

struct Parser {
    let root: Directory
    // By reference, because Directory is a class.
    var cwd: [Directory]
    var isListing: Bool = false

    init() {
        root = Directory()
        cwd = [root]
    }

    mutating func parse(line: String) throws {
        if isListing && !line.starts(with: "$ ") {
            let pieces = line.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
            let name = String(pieces[1])
            if pieces[0] == "dir" {
                cwd.last!.dirs[name] = Directory()
            } else {
                guard let size = Int(pieces[0]) else {
                    throw ParseError()
                }
                cwd.last!.files.append(File(name: name, size: size))
            }
        } else {
            isListing = false
            if line == "$ ls" {
                isListing = true
            } else if line == "$ cd /" {
                cwd = [root]
            } else if line == "$ cd .." {
                guard cwd.count > 1 else {
                    throw ParseError()
                }
                cwd.removeLast()
            } else {
                guard line.starts(with: "$ cd ") else {
                    throw ParseError()
                }
                let name = String(line.dropFirst(5))
                guard let subdir = cwd.last!.dirs[name] else {
                    throw ParseError()
                }
                cwd.append(subdir)
            }
        }
    }
}

var parser = Parser()
while let line = readLine() {
    try parser.parse(line: line)
}
print(parser.root.reduceDirs(0, { sum, dir in
    sum + (dir.size <= 100000 ? dir.size : 0)
}))

let targetSize = 30000000 - (70000000 - parser.root.size)
precondition(targetSize > 0)
print(parser.root.reduceDirs(Int.max, { candidate, dir in
    dir.size > targetSize ? min(candidate, dir.size) : candidate
}))
