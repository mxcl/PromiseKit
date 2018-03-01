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
requireTest.keys().forEach(file => {
  mocha.suite.emit('pre-require', global, file, mocha)
  mocha.suite.emit('require', requireTest(file), file, mocha)
  mocha.suite.emit('post-require', global, file, mocha)
})

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
