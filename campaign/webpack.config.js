var webpack = require('webpack');

module.exports = {
    context: __dirname + '/app',
    entry: {
	app: "./app.js",
	vendors: ['angular']
    },
    output: {
        path: __dirname + '/js',
        filename: "app.bundle.js"
    },
    plugins: [
        new webpack.optimize.CommonsChunkPlugin({name:"vendor", filename:"vendor.bundle.js"})
    ],
    module: {
        loaders: []
    }
};
