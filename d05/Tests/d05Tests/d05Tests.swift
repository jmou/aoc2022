import XCTest
@testable import d05

final class d05Tests: XCTestCase {
    func testSample() throws {
        let lines = """
            [D]    
        [N] [C]    
        [Z] [M] [P]
         1   2   3 

        move 1 from 2 to 1
        move 3 from 1 to 3
        move 2 from 2 to 1
        move 1 from 1 to 2
        """
        let input = Input(fromLines: lines.split(separator: "\n", omittingEmptySubsequences: false))
        var stacks = input.stacks
        stacks.applyP1(steps: input.steps)
        XCTAssertEqual(stacks.tops, "CMZ")
        stacks = input.stacks
        stacks.applyP2(steps: input.steps)
        XCTAssertEqual(stacks.tops, "MCD")
    }
}
