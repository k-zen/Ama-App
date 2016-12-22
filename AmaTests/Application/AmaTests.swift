import XCTest

extension String
{
    func splitOnNewLine () -> [String]
    {
        return self.components(separatedBy: CharacterSet.newlines)
    }
}

class AmaTests: XCTestCase
{
    override func setUp()
    {
        super.setUp()
    }
    
    override func tearDown()
    {
        super.tearDown()
    }
    
    func testExample()
    {
        // Empty
    }
    
    func testPerformanceExample()
    {
        self.measure {
            _ = AKStreamReader(path: Bundle.main.path(forResource: "2015-12-04--09%3A44%3A11,00", ofType:"ama")!)!
        }
    }
}
