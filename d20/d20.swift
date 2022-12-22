infix operator %%

func %%(_ lhs: Int, _ rhs: Int) -> Int {
    let remainder = lhs % rhs
    return remainder < 0 ? remainder + rhs : remainder
}

protocol Shiftable {
    var count: Int { get }
    var array: [Int] { get }
    var translation: [Int] { get }
    subscript(_ index: Int) -> Int { get }
}

extension [Int]: Shiftable {
    var array: [Int] { self }
    var translation: [Int] { Array(indices) }
}

// Structure is unnecessarily contrived because originally used layers of
// wrapping (removed because of poor performance).
struct ShiftedView: Shiftable {
    var base: [Int]
    var baseTranslation: [Int]
    var move: Int
    var offset: Int { base[move] %% (count - 1) }
    var count: Int { base.count }
    var array: [Int] { (0..<count).map({ self[$0] }) }
    var translation: [Int] {
        var result: [Int] = []
        for i in baseTranslation {
            if i == move {
                result.append(mod(i + offset))
            } else if mod(i - move) <= offset {
                result.append(mod(i - 1))
            } else {
                result.append(i)
            }
        }
        return result
    }

    private func mod(_ value: Int) -> Int { value %% count }

    init(base: [Int], translation: [Int], by move: Int) {
        self.base = base
        self.baseTranslation = translation
        self.move = move %% base.count
    }

    subscript(_ index: Int) -> Int {
        if mod(index - move) < offset {
            return base[mod(index + 1)]
        } else if mod(index - move) == offset {
            return base[move]
        } else {
            return base[index]
        }
    }
}

extension Shiftable {
    func groveCoordinates() -> [Int]? {
        guard let zeroIndex = (0..<count).first(where: { self[$0] == 0}) else {
            return nil
        }
        return [1000, 2000, 3000].map({ self[(zeroIndex + $0) % count] })
    }
}

func mix(_ array: any Shiftable) -> any Shiftable {
    var view = array
    for i in 0 ..< view.count {
        view = ShiftedView(base: view.array, translation: view.translation, by: view.translation[i])
    }
    return view
}

func main() {
    var array: [Int] = []
    while let line = readLine() {
        array.append(Int(line)!)
    }

    print(mix(array).groveCoordinates()!.reduce(0, +))

    for i in array.indices {
        array[i] *= 811589153
    }
    var view: Shiftable = array
    for _ in 0..<10 {
        view = mix(view)
    }
    print(view.groveCoordinates()!.reduce(0, +))
}

switch CommandLine.arguments.dropFirst() {
case ["test"]:
    let array = [1, 2, -3, 3, -2, 0, 4]
    var view = ShiftedView(base: array, translation: array.translation, by: 0)
    assert(view.array == [2, 1, -3, 3, -2, 0, 4])
    view = ShiftedView(base: view.array, translation: view.translation, by: view.translation[1])
    assert(view.array == [1, -3, 2, 3, -2, 0, 4])
    view = ShiftedView(base: view.array, translation: view.translation, by: view.translation[2])
    assert(view.array == [1, 2, 3, -2, -3, 0, 4])
    view = ShiftedView(base: view.array, translation: view.translation, by: view.translation[3])
    assert(view.array == [1, 2, -2, -3, 0, 3, 4])
    view = ShiftedView(base: view.array, translation: view.translation, by: view.translation[4])
    assert(view.array == [1, 2, -3, 0, 3, 4, -2])
    view = ShiftedView(base: view.array, translation: view.translation, by: view.translation[5])
    assert(view.array == [1, 2, -3, 0, 3, 4, -2])
    view = ShiftedView(base: view.array, translation: view.translation, by: view.translation[6])
    assert(view.array == [2, -3, 4, 0, 3, -2, 1])
    assert(view.translation.map({ view[$0] }) == array)
    assert(view.groveCoordinates() == [4, -3, 2])

case []:
    main()
default:
    fatalError()
}
