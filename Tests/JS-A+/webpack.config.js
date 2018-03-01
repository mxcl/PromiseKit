var webpack = require('webpack');

module.exports = {
  context: __dirname,
  entry: './index.js',
  output: {
    path: __dirname + '/build',
    filename: 'build.js',
    library: 'library'
  },
  node: {
    fs: 'empty'
  }
};
