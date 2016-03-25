var path = require('path');
var webpack = require('webpack');
var HtmlWebpackPlugin = require('html-webpack-plugin');

var debug = process.env.NODE_ENV !== 'production';

var config = {
  context: path.join(__dirname, 'src'),
  entry: [
    './index.js',
  ],
  output: {
    path: path.join(__dirname, 'dist'),
    filename: 'bundle.js',
    publicPath: '/',
  },
  plugins: [
    new HtmlWebpackPlugin({
      title: "Veq",
    }),
    new webpack.NoErrorsPlugin(),
  ],
  module: {
    loaders: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loaders: [
          'babel',
        ],
      },
      {
        test: /\.css$/,
        loader: 'style!raw',
      },
      {
        test: /\.glsl$/,
        loader: 'webpack-glsl',
        // include: SHADER_PATH,
      },
    ],
  },
  debug: debug,
  devtool: 'source-map',
};

module.exports = config;
