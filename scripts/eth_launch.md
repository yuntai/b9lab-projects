geth --datadir ~/.ethereum/net42 --networkid 42
geth --datadir ~/.ethereum/net42 init ~/genesis42.json
geth --datadir ~/.ethereum/net42 --rpc --rpcport 8545 --rpcaddr 0.0.0.0 --rpccorsdomain "*" --rpcapi "eth,net,web3"
geth attach /home/yuntai/.ethereum/net42/geth.ipc
