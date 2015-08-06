import PromiseKit
import XCTest

// 2.3.3: Otherwise, if x is an object or function.

// This spec is a NOOP for Swift:
//   - We have decided not to interact with other Promises A+ implementations
//   - functions cannot have properties

// 2.3.3.4: If then is not a function, fulfill promise with x.
// - See: The 2.3.4 suite.
