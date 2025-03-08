##  Sample Solidity Funding Pool

This sample Solidity Smart Contract is for a funding pool. It allows for any address to contribute to the funding pool by sending ether directly to the contract. Addresses that have sent ether to the contract would then be eligible to vote. 1 wei = 1 vote. The address that receives the threshold amount of votes (10 ether) would be eligible to get the total balance of the pot.

## Requirements

- the funding pool is a smart contract
- allows anyone to contribute to the funding pool
- funding pool allows for distribution of funds
- funds are distributed wholly (total balance)
- funds are distributed to a single recipient
- the recipient is chosen via voting
- only contributors can vote
- only owner can distribute
- voting weights are proportionate to contributions made to the pool

## Assumptions
- the contract owner can be trusted to only call distribute() after doing due dilligence on the to-be recipient

## Note
- this contract's design makes it a one use contract
- ownership is not transferrable in the current implementation
- `transfer` and `send` will not work since the receive() function requires more than 2300 gas as it calls `_contribute`

## Security Considerations
- there is a reliance on the contract owner to validate the `to` address for `distribute()` (that it has the highest number of votes and is a legitimate candidate)
- this contract allows the contract owner to call `distribute()` for any address that has more than the threshold amount of votes

## Setup and Installation

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) (includes Forge, Cast, and Anvil)
- Git

### Installation

1. Clone the repository
```bash
git clone https://github.com/your-username/solidity-funding-pool.git
cd solidity-funding-pool
```

2. Install dependencies
```bash
forge install
```

### Building the Project

Compile the contracts:
```bash
forge build
```

View contract sizes:
```bash
forge build --sizes
```

### Running Tests

Run all tests:
```bash
forge test
```

Run tests with verbose output:
```bash
forge test -vvv
```

Run a specific test:
```bash
forge test --match-test testFunctionName -vvv
```

### Deployment

1. Set up your environment variables (Create a `.env` file):
```
PRIVATE_KEY=your_private_key
RPC_URL=your_rpc_url
```

2. Deploy to a network:
```bash
source .env
forge script script/FundingPool.sol:FundingPoolScript --rpc-url https://optimism-sepolia.gateway.tenderly.co --account default --sender <SENDER_ADDRESS> --broadcast
```

### Contract Interaction

After deployment, you can interact with the contract using Cast:

1. Contribute funds:
```bash
cast send <CONTRACT_ADDRESS> --value <AMOUNT_IN_ETH>ether --private-key $PRIVATE_KEY
```

2. Vote for a recipient:
```bash
cast send <CONTRACT_ADDRESS> "vote(address,uint256)" <RECIPIENT_ADDRESS> <VOTES_TO_CAST> --private-key $PRIVATE_KEY
```

3. Distribute funds (owner only):
```bash
cast send <CONTRACT_ADDRESS> "distribute(address)" <RECIPIENT_ADDRESS> --private-key $PRIVATE_KEY
```

4. Check contributions:
```bash
cast call <CONTRACT_ADDRESS> "contributions(address)" <CONTRIBUTOR_ADDRESS>
```

5. Check votes received:
```bash
cast call <CONTRACT_ADDRESS> "votesReceived(address)" <RECIPIENT_ADDRESS>
```

## Development

### Local Testing with Anvil

1. Start a local Ethereum node:
```bash
anvil
```

2. Deploy to local node:
```bash
forge script script/FundingPool.sol:FundingPoolScript --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

The private key above is Anvil's default first account private key.

### Code Coverage

Generate test coverage report:
```bash
forge coverage
```

### Gas Report

Generate gas usage report:
```bash
forge test --gas-report
```