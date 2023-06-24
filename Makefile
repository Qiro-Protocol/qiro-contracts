# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

all: clean remove install update solc build 

# Install proper solc version.
solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_10

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install the Modules
install :; 
	forge install dapphub/ds-test 
	forge install OpenZeppelin/openzeppelin-contracts

# Update Dependencies
update:; forge update

# Builds
build  :; forge clean && forge build --optimize --optimizer-runs 1000000

setup-yarn:
	yarn 

local-node: setup-yarn 
	yarn hardhat node 

deploy:
	forge create ${path}/${contract}.sol:${contract} --constructor-args-path args --etherscan-api-key ${api} --private-key ${pk}  --rpc-url ${rpc} --verify
	
testing:
	forge test --fork-url ${rpc} --match-contract ${contract} --gas-report -vv

slither:
	slither --config-file slither.config.json src/${contract}

slither-print:
	slither --config-file slither.config.json src/${contract} --print modifiers
# https://github.com/crytic/slither/wiki/Printer-documentation