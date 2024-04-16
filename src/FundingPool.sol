// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

// NOTE: This contract is not yet complete.

error NoZeroValue();

contract FundingPool {
    mapping(address => uint256) public votes; // address to distribute to
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public spentContributions;
    uint256 public threshold = 10 ether;
    bool public distributed = false;

    function vote(uint256 numToCast) public {
        // TODO: check that numToCast <= contributions[msg.sender]
        // TODO: error if contributions = spentContributions
    }

    function distribute() public {
        // TODO: error if threshold not met
        distributed = true;
    }

    receive () payable external {
        if ( msg.value == 0 ) revert NoZeroValue();
        contributions[msg.sender] += msg.value;
    }
}
