// some like Rust impl
// any like Rust dyn

struct StdinLines: Sequence, IteratorProtocol {
    typealias Element = String
    func next() -> String? {
        return readLine()
    }
}

protocol MatrixView<Element> {
    associatedtype Element
    subscript(_ i: Int, _ j: Int) -> Element? { get set }
    var width: Int { get }
    var height: Int { get }
}

fileprivate class TransposedMatrixView<T>: MatrixView {
    var matrix: any MatrixView<T>

    init(matrix: any MatrixView<T>) {
        self.matrix = matrix
    }

    subscript(_ i: Int, _ j: Int) -> T? {
        get {
            return matrix[j, matrix.width - 1 - i]
        }
        set {
            matrix[j, matrix.width - 1 - i] = newValue
        }
    }

    var width: Int {
        return matrix.height
    }

    var height: Int {
        return matrix.width
    }
}

extension MatrixView {
    var rows: Range<Int> {
        return 0 ..< height
    }

    var columns: Range<Int> {
        return 0 ..< width
    }

    func transposed() -> any MatrixView<Element> {
        return TransposedMatrixView(matrix: self)
    }
}

class Matrix<T>: MatrixView {
    var elements: [T]
    var width: Int

    init(repeating value: T, width: Int, height: Int) {
        self.width = width
        self.elements = Array(repeating: value, count: width * height)
    }

    init(elements: some Sequence<some Sequence<T>>) {
        self.elements = []
        self.width = 0
        for row in elements {
            let row = Array(row)
            if self.width == 0 {
                self.width = row.count
            } else {
                precondition(self.width == row.count)
            }
            self.elements += row
        }
    }

    var height: Int {
        assert(elements.count % width == 0)
        return elements.count / width
    }

    private func realIndex(_ i: Int, _ j: Int) -> Int? {
        let index = i * width + j
        guard j < width, index < elements.count else {
            return nil
        }
        return index
    }

    subscript(_ i: Int, _ j: Int) -> T? {
        get {
            guard let index = realIndex(i, j) else {
                return nil
            }
            return elements[index]
        }
        set {
            guard let index = realIndex(i, j) else {
                preconditionFailure("Out of bounds")
            }
            guard let newValue else {
                preconditionFailure("Cannot unset Matrix element")
            }
            elements[index] = newValue
        }
    }
}

struct Forest {
    var trees: Matrix<Int>

    init(from lines: some Sequence<some StringProtocol>) {
        self.trees = Matrix(elements: lines.lazy.map { $0.lazy.map { Int(String($0))! } })
    }

    var visible: Int {
        let realVisible = Matrix(repeating: false, width: trees.width, height: trees.height)
        var trees: any MatrixView<Int> = trees
        var visible: any MatrixView<Bool> = realVisible
        for _ in 0...3 {            
            for i in trees.rows {
                var min = -1
                for j in trees.columns {
                    if trees[i, j]! > min {
                        visible[i, j] = true
                        min = trees[i, j]!
                    }
                }
            }
            trees = trees.transposed()
            visible = visible.transposed()
        }
        return realVisible.elements.lazy.filter { $0 == true }.count
    }

    static func viewingDistanceRight(trees: some MatrixView<Int>, i: Int, j: Int) -> Int {
        if j == trees.width - 1 {
            return 0
        }
        let visibleTo = (j + 1 ..< trees.width).first(where: { trees[i, $0]! >= trees[i, j]! })
        return (visibleTo ?? trees.width - 1) - j
    }

    func scenicScore(_ i: Int, _ j: Int) -> Int {
        var i = i
        var j = j
        var score = 1
        var trees: any MatrixView<Int> = trees
        for _ in 0...3 {
            score *= Forest.viewingDistanceRight(trees: trees, i: i, j: j)
            trees = trees.transposed()
            (i, j) = (trees.width - 1 - j, i)  // "undo" transposition
        }
        return score
    }

    func bestScenicScore() -> Int {
        return trees.rows.lazy.flatMap { i in
            trees.columns.lazy.map { j in scenicScore(i, j) }
        }.max()!
    }
}

switch CommandLine.arguments.dropFirst() {
case ["test"]:
    let sample = """
    30373
    25512
    65332
    33549
    35390
    """
    let forest = Forest(from: sample.split(separator: "\n"))
    print(forest.visible)
    print(forest.bestScenicScore())

case []:
    let forest = Forest(from: StdinLines())
    print(forest.visible)
    print(forest.bestScenicScore())

default:
    fatalError()
}
