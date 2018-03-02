var webpack = require('webpack');

module.exports = {
  mode: 'development',
  context: __dirname,
  entry: './index.js',
  output: {
    path: __dirname + '/build',
    filename: 'build.js',
    library: 'runTests'
  },
  node: {
    fs: 'empty'
  },
};
