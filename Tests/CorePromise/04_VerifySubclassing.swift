import PromiseKit

/**
 Verify expected subclassing possibilities still compile.
 */
public class SubclassTest: Promise<Int> {
    private let foo: Int


    public required init(resolvers: (@escaping (Int) -> Void, @escaping (Error) -> Void) throws -> Void) {
        foo = 2
        super.init(resolvers: resolvers)
    }

    public required init(error: Error) {
        foo = 3
        super.init(error: error)
    }

    public required init(value: Int) {
        foo = 4
        super.init(value: value)
    }

    public class func bar() -> Self {
        return self.init(value: 5)
    }
}
