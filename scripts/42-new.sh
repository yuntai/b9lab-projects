rm -rf ~/.ethereum/eth42
rm -rf ~/.ethash
geth --datadir ~/.ethereum/net42 --networkid 42 init 42-genesis.json
