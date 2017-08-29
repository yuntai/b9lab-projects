#!/opt/local/bin/node
const Web3 = require("web3");
const web3 = new Web3(new Web3.providers.IpcProvider(
	process.env['HOME'] + '/.ethereum/testnet/geth.ipc',
  require('net')));

const Rx = require('rx');
const Rxifier = require('./rxifyWeb3.js');
console.log("web3=",web3);
Rxifier.rxify(web3);

// Get the latest block number
const blockNumbersObservable = web3.eth.getBlockNumberObservable()
  .concatMap(function(latestBlockNumber) {
    return Rx.Observable.create(function (observer) {
      for(var blockNumber = latestBlockNumber; 0 <= blockNumber; blockNumber--) {
        // Return all block numbers from the latest to the earliest
        observer.onNext(blockNumber);
      }
      observer.onCompleted();
    });
  })
  .controlled(); // Prevent "flooding"

const blockAndTxIndexObservable = blockNumbersObservable
    .concatMap(web3.eth.getBlockObservable)
    .concatMap(function (blockInfo) {
      blockNumbersObservable.request(1);
      var txCount = blockInfo.transactions.length;
      return Rx.Observable.create(function (observer) {
        if(txCount == 0) {
          observer.onNext({
            blockNumber: blockInfo.number,
            txIndex: null
          });
        }
        for(var txIndex = 0; txIndex < txCount; txIndex++) {
          observer.onNext({
            blockNumber: blockInfo.number,
            txIndex: txIndex
          });
        }
        observer.onCompleted();
      });
    })
    .controlled();

blockAndTxIndexObservable.concatMap((blockNumberAndTxIndex) =>
  web3.eth.getTransactionFromBlockObservable(
    blockNumberAndTxIndex.blockNumber,
    blockNumberAndTxIndex.txIndex)
  )
  .subscribe(function (txInfo) {
    blockAndTxIndexObservable.request(1);
    console.log(
      txInfo.blockNumber, "-",
      txInfo.transactionIndex, ": ",
      txInfo.from);
  },
  function(error) {
    console.error(error);
  });

blockNumbersObservable.request(1);
blockAndTxIndexObservable.request(1);
