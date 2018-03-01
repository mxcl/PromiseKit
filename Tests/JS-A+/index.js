require('mocha')

// const adapter = {
//   resolved: () => { return null; console.log(arguments) },
//   rejected: () => { return null; console.log(arguments) },
//   deferred: () => { return null; console.log(arguments) },
//   promise: {}
// }

// const adapter = new JSAdapter()

module.exports = function(adapter, done) {
  
  console.log(adapter.resolved())
  console.log(adapter.rejected())
  console.log(adapter.deferred())
  
  global.adapter = adapter
  const mocha = new Mocha({ ui: 'bdd' })

  // Require all tests
  const requireTest = require.context('promises-aplus-tests/lib/tests', false, /\.js$/)
  requireTest.keys().forEach(file => {
    console.log('requiring' + file)
    mocha.suite.emit('pre-require', global, file, mocha)
    mocha.suite.emit('require', requireTest(file), file, mocha)
    mocha.suite.emit('post-require', global, file, mocha)
  })

  const runner = mocha.run(failures => {
    done(failures)
  })
}