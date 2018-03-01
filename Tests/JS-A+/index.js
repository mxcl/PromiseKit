// const promisesAplusTests = require('promises-aplus-tests')
// 
require('mocha')



const adapter = {
  resolved: () => { console.log(arguments) },
  rejected: () => { console.log(arguments) },
  deferred: () => { console.log(arguments) },
  promise: {}
}

global.adapter = adapter
const mocha = new Mocha({ui: 'bdd'})

// Require all tests
const requireTest = require.context('promises-aplus-tests/lib/tests', false, /\.js$/)
requireTest.keys().forEach(key => requireTest(key))

mocha.run(failures => {
  delete global.adapter
  consoleLog(failures)
})

module.exports = "1"

// 
// 
// 
// promisesAplusTests(adapter, err => {
//   console.error(error)
// })
// 
// module.exports = promisesAplusTests
