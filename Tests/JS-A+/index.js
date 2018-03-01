// const promisesAplusTests = require('promises-aplus-tests')
// 
require('mocha')

const adapter = {
  resolved: () => { return null; console.log(arguments) },
  rejected: () => { return null; console.log(arguments) },
  deferred: () => { return null; console.log(arguments) },
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

// console.log("Starting")
const runner = mocha.run(failures => {
  delete global.adapter
  console.log(failures)
})
// 
// runner.on('suite', function (suite) {
//   console.log('on(\'suite\') called');
// });
// 
// runner.on('fail', function (test, err) {
//   console.log('on(\'fail\') called');
// });
// 
// runner.on('pass', function (test) {
//   console.log('on(\'pass\') called');
// });
// 
// runner.on('test end', function (test, err) {
//   console.log('on(\'test end\') called');
// });
// 
// runner.on('end', function () {
//   console.log('on(\'end\') called');
// });

module.exports = "1"
