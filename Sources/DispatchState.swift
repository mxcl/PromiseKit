import Dispatch

/// A LocationWithinChain is a little state machine that tracks progress along the promise chain.
/// It detects and remembers the boundary between the body and the tail of the chain. The
/// tail begins at the first instance of `done`, `catch`, or `finally`.
///
/// In addition, a chain dispatcher that was set somewhere within the body of a chain requires
/// "confirmation" at the point of transition to the tail. An unconfirmed chain executes normally,
/// but PromiseKit logs an error.
///
/// To confirm, the first use of a chain dispatcher within the tail must be explicit. The easiest
/// way to do this is simply to include `on: .chain` in the argument of a PromiseKit function.
/// You may also set a chain dispatcher explicitly through `dispatch(on:)`.
///
/// The idea is that it's easy to receive a chain with a chain dispatcher from lower-level code,
/// or to set a dispatcher without realizing that it will continue all the way to the end of the
/// chain unless you explicitly cancel it. So the user has to acknowledge that they want the chain
/// dispatcher to continue or they'll be warned.

enum LocationWithinChain {
    
    case inBody     // Known to be prior to body/tail transition
    case inTail     // Have entered tail, but not reached confirmation point (if there is one)
    case primed     // Chain dispatcher set, but we haven't seen the next closure yet; could be body or tail
    case confirmed  // API calls have confirmed the chain dispatcher, if any
    case warned     // Did not confirm the chain dispatcher; did (or should) warn
    
    var isInTail: Bool {
        return self == .inTail || self == .confirmed || self == .warned
    }
    
    /// Determine the next LocationWithinChain using the old value and information about the
    /// context of the next dispatch.
    ///
    /// - Parameters:
    ///   - isTail: Current function is a tail function (`done`, `catch`, or `finally`)
    ///   - explicit: Current dispatch is explicit (e.g., `on: dispatcher`)
    ///   - hasChain: This chain has a chain dispatcher
    ///   - usedChain: The upcoming dispatcher was determined by the chain dispatcher
    
    mutating func advanceLocation(isTailFunction isTail: Bool, explicitDispatch explicit: Bool, hasChain: Bool, usedChain: Bool) {
        switch self {
            case .inBody:
                if !isTail { self = .inBody; return }
                fallthrough
            case .inTail:
                if !hasChain { self = .inTail; return }
                switch (explicit, usedChain) {
                    case (true, true): self = .confirmed
                    case (true, false): self = .inTail
                    case (false, _): self = .warned
                }
            case .primed:
                if !hasChain { fatalError("Shouldn't happen: primed confirmation state with no chain dispatcher") }
                self = isTail ? .confirmed : .inBody
            case .confirmed, .warned:
                // Terminal states
                return
        }
    }
    
    // Called by `dispatch(on: .chain), which doesn't have an inherent "is tail function" value
    mutating func confirm() {
        if self == .inTail || self == .primed {
            self = .confirmed
        }
    }
}

protocol HasDispatchState {
    var dispatchState: DispatchState { get set }
}

/// If you have a DispatchState, you can dispatch to it. This is essentially the
/// Dispatcher protocol, but that's public and all the DispatchState-related
/// items are internal.

extension HasDispatchState {
    func dispatch(_ body: @escaping () -> Void) {
        dispatchState.dispatch(body)
    }
}

typealias SourcedDispatcher = (
    dispatcher: Dispatcher,  // Dispatcher to use for dispatching this closure
    explicit: Bool           // Dispatcher chosen explicitly, or is it an implicit or default selection?
)

/// A DispatchState tracks the state of the promise chain and stores the dispatcher
/// to be used for upcoming closures. It also tracks the chain dispatcher, if there
/// is one.
///
/// Every Thenable has a DispatchState.

struct DispatchState: Dispatcher {
    
    fileprivate var dispatcher: Dispatcher = conf.dd     // Most recently used, or for next state, dispatcher to use
    private var chainStrategy: ChainDispatchStrategy?    // Active chain dispatcher, if any
    private var location: LocationWithinChain = .inBody  // Confirmation process tracker
    
    /// This is just a notational/Demeter convenience so clients don't have to fish out the
    /// dispatcher themselves. DispatchStates should not be used as regular Dispatchers.

    func dispatch(_ body: @escaping () -> Void) {
        dispatcher.dispatch(body)
    }
    
    /// Calculate the next state, configured for chain dispatching
    
    func dispatch(on: Dispatcher) -> DispatchState {
        
        var state = nextState(givenDispatcher: on)
        
        if let on = on as? SentinelDispatcher {
            switch on.type {
                case .unspecified:
                    fatalError("`dispatch(on:)` requires a specific dispatcher")
                case .default:
                    state.chainStrategy = nil
                    // Not necessary to update phase
                case .chain:
                    if state.chainStrategy != nil {
                        conf.logHandler(.chainWithoutChainDispatcher)
                    } else {
                        // Does not change chain dispatcher, but does confirm if appropriate
                        state.location.confirm()
                    }
                case .sticky:
                    state.chainStrategy = StickyStrategy()
                    state.location = .primed
            }
        } else {
            state.chainStrategy = StandardStrategy(dispatcher: state.dispatcher)
            state.location = .primed
        }
        
        return state
    }
    
    /// Given a Dispatcher (which may be a SentinelDispatcher encoding various special options (`.default`,
    /// `.chain`, `.sticky`, or not specified) and an indication of whether the current function is a
    /// tail-initiating function (that is, `done`, `catch`, or `finally`), produce the next DispatchState.
    /// This is the DispatchState for the promise to be returned by the current function.
    
    func nextState(givenDispatcher given: Dispatcher, isTailFunction isTail: Bool = false) -> DispatchState {
        
        var nextState = self
        
        // First offer the context to the chain dispatcher (if any) to see if it's interested in
        // handling the current situation. If not, fall back to standard dispatching.
        if let chainDispatcher = chainStrategy, let chainResponse = chainDispatcher.nextDispatcher(previous: self, givenDispatcher: given) {
            nextState.dispatcher = chainResponse.dispatcher
            nextState.location.advanceLocation(isTailFunction: isTail, explicitDispatch: chainResponse.explicit,
                hasChain: true, usedChain: true)
        } else {
            let disp = nextDispatcher(givenDispatcher: given, isTailFunction: isTail)
            nextState.dispatcher = disp.dispatcher
            nextState.location.advanceLocation(isTailFunction: isTail, explicitDispatch: disp.explicit,
                hasChain: chainStrategy != nil, usedChain: false)
        }
        
        // If we still have the initially-assigned default dispatcher, replace it with the global default
        if let sentinel = nextState.dispatcher as? SentinelDispatcher, sentinel.type == .unspecified {
            nextState.dispatcher = isTail || nextState.location.isInTail ? conf.D.tail : conf.D.body
        }

        // If we have DispatchWorkItemFlags from a wrapper invocation, try to apply them to the dispatcher.
        if let sentinel = given as? SentinelDispatcher {
            nextState.dispatcher = sentinel.applyFlags(to: nextState.dispatcher)
        }

        // If we are transitioning into the `.warned` confirmation state, print a warning about
        // the need to confirm the chain dispatcher.
        if location != .warned && nextState.location == .warned && conf.requireChainDispatcherConfirmation {
            conf.logHandler(.failedToConfirmChainDispatcher)
        }
        
        return nextState
    }
    
    /// This is the basic dispatcher selection engine. In addition to an actual dispatcher, it
    /// returns an indication of whether the dispatcher was selected explicitly or implicitly.
    
    private func nextDispatcher(givenDispatcher given: Dispatcher, isTailFunction isTail: Bool) -> SourcedDispatcher {
        
        var defaultDispatcher: Dispatcher { return isTail || location.isInTail ? conf.D.tail : conf.D.body }
        
        // Fake dispatcher - sentinel values propagated from wrapper
        if let sentinel = given as? SentinelDispatcher {
            switch sentinel.type {
                case .unspecified:
                    return (dispatcher: defaultDispatcher, explicit: false)
                case .default:
                    return (dispatcher: defaultDispatcher, explicit: true)
                case .chain:
                    // ChainDispatchStrategy should have claimed this
                    fatalError("`on: .chain` used without a chain dispatcher")
                case .sticky:
                    // Repeat previous dispatcher
                    return (dispatcher: self.dispatcher, explicit: true)
            }
        }
        
        // Real dispatcher
        return (dispatcher: given, explicit: true)
    }
}

/// Chain dispatchers can potentially participate actively in the dispatch process,
/// so they are strategy objects rather than just flat Dispatchers. A chain dispatch
/// strategy may decline to participate in dispatcher selection by returning nil.

protocol ChainDispatchStrategy {
    func nextDispatcher(previous: DispatchState, givenDispatcher given: Dispatcher) -> SourcedDispatcher?
}

/// Mimics a flat chain Dispatcher object
struct StandardStrategy: ChainDispatchStrategy {
    
    let dispatcher: Dispatcher
    
    func nextDispatcher(previous: DispatchState, givenDispatcher given: Dispatcher) -> SourcedDispatcher? {
        
        // Chain dispatcher has nothing to say about explicitly specified dispatchers
        guard let sentinel = given as? SentinelDispatcher else { return nil }
        
        switch sentinel.type {
            case .default:
                // Explicit; punt
                return nil
            case .unspecified:
                return (dispatcher: dispatcher, explicit: false)
            case .chain:
                return (dispatcher: dispatcher, explicit: true)
            case .sticky:
                return nil
            
        }
    }
}

/// The sticky strategy repeats the previous Dispatcher selection
struct StickyStrategy: ChainDispatchStrategy {
    
    func nextDispatcher(previous: DispatchState, givenDispatcher given: Dispatcher) -> SourcedDispatcher? {
        
        if let sentinel = given as? SentinelDispatcher {
            switch sentinel.type {
                case .default:
                    // Explicit; punt
                    return nil
                case .unspecified:
                    return (dispatcher: previous.dispatcher, explicit: false)
                case .chain, .sticky:
                    return (dispatcher: previous.dispatcher, explicit: true)
            }
        } else {
            // Claim an explicit dispatcher because we do want to ratify the chain dispatcher in this case
            return (dispatcher: given, explicit: true)
        }
    }
}

// Unfortunately, DispatchState is a PromiseKit internal type, so it's impossible
// to add a protocol to, e.g., Thenable to certify that any particular Thenable
// has a DispatchState. The protocol would have to mention DispatchState, and
// therefore have "internal" access level, but you can't extend an internal protocol
// in a public protocol. This glue skirts that issue.

extension Thenable {
    var dispatchState: DispatchState {
        get { return getDispatchState(self) }
        set { setDispatchState(self, state: newValue) }
    }
}

extension CatchMixin {
    var dispatchState: DispatchState {
        get { return getDispatchState(self) }
        set { setDispatchState(self, state: newValue) }
    }
}

func getDispatchState(_ entity: AnyObject) -> DispatchState {
    if let hasState = entity as? HasDispatchState {
        return hasState.dispatchState
    } else {
        fatalError("PromiseKit base object that should have a DispatchState in fact does not")
    }
}

func setDispatchState(_ entity: AnyObject, state: DispatchState) {
    if var hasState = entity as? HasDispatchState {
        hasState.dispatchState = state
    } else {
        fatalError("PromiseKit base object that should have a DispatchState in fact does not")
    }
}
