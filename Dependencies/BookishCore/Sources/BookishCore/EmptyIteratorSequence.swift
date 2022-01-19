// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 19/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

#if ENABLE_EMPTY_ITERATOR

public protocol EmptyIteratorSequence: Sequence {
    static var emptyIterator: Iterator { get }
}

extension Optional: Sequence where Wrapped: EmptyIteratorSequence {
    public typealias Element = Wrapped.Element
    public typealias Iterator = Wrapped.Iterator

    public func makeIterator() -> Wrapped.Iterator {
        switch self {
            case .none:
                return Wrapped.emptyIterator
            case .some(let wrapped):
                return wrapped.makeIterator()
        }
    }
}

#endif
