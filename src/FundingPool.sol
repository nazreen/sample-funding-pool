// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

// NOTE: This contract should not be used for Production as it is for educational purposes only. You may contact me if you'd like to have a version for Production.

error NoZeroValue();
error InsufficientUnspentContributions();
error ThresholdNotMet();
error alreadyDistributed();

contract FundingPool {
    event VoteCasted(address indexed voter, uint256 indexed numCasted);
    event Distribution(address indexed to, uint256 indexed amount);

    mapping(address => uint256) public votesReceived; // address to distribute to
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public spentContributions;
    uint256 public threshold = 10 ether;
    bool public distributed = false;

    function vote(address voteRecipient, uint256 numToCast) public {
        // check has sufficient contributions
        uint256 unspentContributions = contributions[msg.sender] - spentContributions[msg.sender];
        if (unspentContributions < numToCast) {
            revert InsufficientUnspentContributions();
        }

        votesReceived[voteRecipient] += numToCast;
        spentContributions[msg.sender] += numToCast;
        emit VoteCasted(voteRecipient, numToCast);
    }

    function distribute(address to) public {
        // TODO: error if threshold not met
        if (distributed) {
            revert alreadyDistributed();
        }
        if (votesReceived[to] < threshold) {
            revert ThresholdNotMet();
        }
        // threshold met
        distributed = true;
        uint256 amount = address(this).balance;        
        (bool ok, ) = payable(address(to)).call{value: amount}("");
        require(ok, "ether transfer failed");
        // send funds
        emit Distribution(to, amount);
    }

    function _contribute() internal {
        if ( msg.value == 0 ) revert NoZeroValue();
        contributions[msg.sender] += msg.value;
    }

    receive () payable external {
        _contribute();
    }
}
