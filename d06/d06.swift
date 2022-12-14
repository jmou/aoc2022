func findDistinct(input: String, count: Int) -> Int? {
    var window = [Character?](repeating: nil, count: count)
    for (i, char) in input.enumerated() {
        if window[0] != nil && Set(window).count == count {
            return i
        }
        window.removeFirst()
        window.append(char)
    }
    return nil
}

let input = readLine()!
print(findDistinct(input: input, count: 4)!)
print(findDistinct(input: input, count: 14)!)
