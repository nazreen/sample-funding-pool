// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

// NOTE: This contract is not yet complete.

error NoZeroValue();

contract FundingPool {
    event VoteCasted(address indexed voter, uint256 indexed numCasted);

    mapping(address => uint256) public votesReceived; // address to distribute to
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public spentContributions;
    uint256 public threshold = 10 ether;
    bool public distributed = false;

    function vote(address voteRecipient, uint256 numToCast) public {
        votesReceived[voteRecipient] += numToCast;
        spentContributions[msg.sender] += numToCast;
        emit VoteCasted(voteRecipient, numToCast);
        // TODO: check that numToCast <= contributions[msg.sender]
        // TODO: error if contributions = spentContributions
    }

    function distribute() public {
        // TODO: error if threshold not met
        distributed = true;
    }

    // note: we should also have a function that performs the same function as receive
    receive () payable external {
        if ( msg.value == 0 ) revert NoZeroValue();
        contributions[msg.sender] += msg.value;
    }
}
