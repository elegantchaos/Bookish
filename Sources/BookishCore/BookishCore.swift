import Logger
import Actions

class TestAction: Action {
    
}

public class BookishCore {
    public static let Version = "1.0"
    
    public init() {
        
    }
    
    public func test() {
        let channel = Logger("test")
        channel.log("test")
    }
}

