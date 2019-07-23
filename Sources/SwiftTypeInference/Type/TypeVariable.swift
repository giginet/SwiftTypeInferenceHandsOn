import Foundation

public struct TypeVariable : Type, Hashable {
    public var id: Int
    
    public init(id: Int) {
        self.id = id
    }
    
    public var description: String {
        return "$t\(id)"
    }
}
