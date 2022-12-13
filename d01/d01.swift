var calories: [Int] = []

var sum = 0
while let line = readLine() {
    if line.isEmpty {
        calories.append(sum)
        sum = 0
    } else {
        sum += Int(line)!
    }
}
calories.append(sum)

calories.sort()
print(calories.last!)
print(calories.suffix(from: calories.endIndex - 3).reduce(0, +))
