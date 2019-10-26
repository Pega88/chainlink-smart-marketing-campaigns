#!/bin/bash
mkdir  ~/.chainlink-ropsten

## REMARK - fill API key for fiews for this to work!
## Syncing local eth node took to long to sync.
## Fiews free tier running for chainlink node until Nov 9th.
echo "ROOT=/chainlink
LOG_LEVEL=debug
ETH_CHAIN_ID=3
MIN_OUTGOING_CONFIRMATIONS=2
LINK_CONTRACT_ADDRESS=0x20fe562d797a42dcb3399062ae9546cd06f63280
CHAINLINK_TLS_PORT=0
SECURE_COOKIES=false
ALLOW_ORIGINS=*
ORACLE_CONTRACT_ADDRESS=0x65d1d8f064326ce10ae3ffb57454a48a4e8cba7f
ETH_URL=wss://cl-ropsten.fiews.io/v1/API_KEY_GOES_HERE" > ~/.chainlink-ropsten/.env

cd ~/.chainlink-ropsten

docker run \
	-p 6688:6688 \
	-v ~/.chainlink-ropsten:/chainlink \
	-it \
	--env-file=.env \
	smartcontract/chainlink \
	local n