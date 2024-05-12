##  Sample Solidity Funding Pool

This sample Solidity Smart Contract is for a funding pool. It allows for any address to contribute to the funding pool by sending ether directly to the contract. Addresses that have sent ether to the contract would then be eligible to vote. 1 wei = 1 vote. The address that receives the threshold amount of votes (10 ether) would be eligible to get the total balance of the pot.

Requirements:

- the funding pool is a smart contract
- allows anyone to contribute to the funding pool
- funding pool allows for distribution of funds
- funds are distributed wholly (total balance)
- funds are distributed to a single recipient
- the recipient is chosen via voting
- only contributors can vote
- only owner can distribute
- voting weights are proportionate to contributions made to the pool

Assumptions
- the contract owner can be trusted to only call distribute() after doing due dilligence on the to-be recipient

Note:
- this contract's design makes it a one use contract
- ownership is not transferrable in the current implementation
- `transfer` and `send` will not work since the receive() function requires more than 2300 gas as it calls `_contribute`

Security Considerations
- there is a reliance on the contract owner to validate the `to` address for `distribute()` (that it has the highest number of votes and is a legitimate candidate)
- this contract allows the contract owner to call `distribute()` for any address that has more than the threshold amount of votes
