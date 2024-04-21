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
- voting weights are proportionate to contributions made to the pool

Note:
- this contract's design makes it a one use contract

Security Considerations
- this contract allows an attacker to steal the whole balance of the funding pool just by supplying the difference between the threshold and the current contract's balance. one way to mitigate against this is to allow only the contract owner to call the distribute() function, under the assumption that the contract owner would do due dilligence on the to address.
- this contract allows for an attacker to steal the whole balance of the funding pool even if there is another address that has a higher number of votes. e.g. address a has 20 ether of votes. an attacker could simply contribute 10 ether to his own address, and then call distribute to that address, netting him the 20 ether voted to the original address + his 10 ether back + the remainder balance in the contract.
