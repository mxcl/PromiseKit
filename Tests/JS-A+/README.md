Promises/A+ Compliance Test Suite (JavaScript)
==============================================

What is this?
-------------

This contains the necessary Swift and JS files to run the Promises/A+ compliance test suite from PromiseKit's unit tests.

 - Promise/A+ Spec: <https://promisesaplus.com/>
 - Compliance Test Suite: <https://github.com/promises-aplus/promises-tests>

Run tests
---------

```
$ npm install
$ npm run build
```

then open `PromiseKit.xcodeproj` and run the `PMKJSA+Tests` unit test scheme.

Known limitations
-----------------

See `ignoredTests` in `index.js`.


 - 2.3.3 is disabled: Otherwise, if x is an object or function. This spec is a NOOP for Swift:
  - We have decided not to interact with other Promises A+ implementations
  - functions cannot have properties

Upgrade the test suite
----------------------

```
$ npm install --save promises-aplus-tests@latest
$ npm run build
```

Develop
-------

JavaScriptCore is a bit tedious to work with so here are a couple tips in case you're trying to debug the test suite.

If you're editing JS files, enable live rebuilds:

```
$ npm run watch
```

If you're editing Swift files, a couple things you can do:

 - You can adjust `testName` in `AllTests.swift` to only run one test suite
 - You can call `JSUtils.printCurrentStackTrace()` at any time. It won't contain line numbers but some of the frame names might help.

How it works
------------

The Promises/A+ test suite is written in JavaScript but PromiseKit is written in Swift/ObjC. For the test suite to run against swift code, we expose a promise wrapper `JSPromise` inside a JavaScriptCore context. This is done in a regular XCTestCase.

Since JavaScriptCore doesn't support CommonJS imports, we inline all the JavaScript code into `build/build.js` using webpack. This includes all the npm dependencies (`promises-aplus-tests`, `mocha`, `sinon`, etc) as well as the glue code in `index.js`.

`build.js` exposes one global variable `runTests(adapter, onFail, onDone, [testName])`. In our XCTestCase, a shared JavaScriptCore context is created, `build.js` is evaluated and now `runTests` is accessible from the Swift context.

In our swift test, we create a JS-bridged `JSPromise` which only has one method `then(onFulfilled, onRejected) -> Promise`. It wraps a swift `Promise` and delegates call `then` calls to it.

An [adapter](https://github.com/promises-aplus/promises-tests#adapters) – plain JS object which provides `revoled(value), rejected(reason), and deferred()` – is passed to `runTests` to run the whole JavaScript test suite.

Errors and end events are reported back to Swift and piped to `XCTFail()` if necessary.

Since JavaScriptCore isn't a node/web environment, there is quite a bit of stubbing necessary for all this to work:

 - The `fs` module is stubbed with an empty function
 - `console.log` redirects to `Swift.print` and provides only basic format parsing
 - `setTimeout/setInterval` are implemented with `Swift.Timer` behind the scenes and stored in a `[TimerID: Timer]` map.
