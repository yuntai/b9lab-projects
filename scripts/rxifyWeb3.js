const Rx = require('rx');

module.exports = {
    rxify: function (web3) {
        // List synchronous functions masquerading as values.
        var syncGetters = {
            db: [],
            eth: [ "accounts", "blockNumber", "coinbase", "gasPrice", "hashrate",
                "mining", "protocolVersion", "syncing" ],
            net: [ "listening", "peerCount" ],
            personal: [ "listAccounts" ],
            shh: [],
            version: [ "ethereum", "network", "node", "whisper" ]
        };

        Object.keys(syncGetters).forEach(function(group) {
            if(web3[group]) {
              Object.keys(web3[group]).forEach(function (method) {
                  if (syncGetters[group].indexOf(method) > -1) {
                      // Skip
                  } else if (typeof web3[group][method] === "function") {
                      web3[group][method + "Observable"] = Rx.Observable.fromNodeCallback(web3[group][method]);
                  }
              });
            }
        });
    },
};
