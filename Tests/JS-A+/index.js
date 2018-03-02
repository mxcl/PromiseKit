require('mocha')

module.exports = function(adapter, done) {
  
  global.adapter = adapter
  const mocha = new Mocha({ ui: 'bdd' })

  // Require all tests
  const requireTest = require.context('promises-aplus-tests/lib/tests', false, /\.js$/)
  requireTest.keys().forEach(file => {
    mocha.suite.emit('pre-require', global, file, mocha)
    mocha.suite.emit('require', requireTest(file), file, mocha)
    mocha.suite.emit('post-require', global, file, mocha)
  })

  const runner = mocha.run(failures => {
    done(failures)
  })
  
  runner.on('fail', (test, err) => {
    console.error(err)
  })
}
