const _ = require('lodash')
require('mocha')

// Ignored by design
const ignoredTests = [
  '2.3.3'
]

module.exports = function(adapter, onFail, onDone, testName) {
  
  global.adapter = adapter
  const mocha = new Mocha({ ui: 'bdd' })

  // Require all tests
  console.log('Loading test files')
  const requireTest = require.context('promises-aplus-tests/lib/tests', false, /\.js$/)    
  requireTest.keys().forEach(file => {
    
    let currentTestName = _.replace(_.replace(file, './', ''), '.js', '')
    if (testName && currentTestName !== testName) {
      return
    }
    
    if (_.includes(ignoredTests, currentTestName)) {
      return
    }
    
    console.log(`\t${currentTestName}`)
    mocha.suite.emit('pre-require', global, file, mocha)
    mocha.suite.emit('require', requireTest(file), file, mocha)
    mocha.suite.emit('post-require', global, file, mocha)
  })

  const runner = mocha.run(failures => {
    onDone(failures)
  })
  
  runner.on('fail', (test, err) => {
    console.error(err)
    onFail(test.title, err)
  })
}
