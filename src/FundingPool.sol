// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

// NOTE: This contract should not be used for Production as it is for educational purposes only. You may contact me if you'd like to have a version for Production.

error NoZeroValue();
error InsufficientUnspentContributions();
error ThresholdNotMet();
error AlreadyDistributed();
error Unauthorized();

contract FundingPool {
    event VoteCasted(address indexed voter, uint256 indexed numCasted);
    event Distribution(address indexed to, uint256 indexed amount);

    address public owner;

    mapping(address => uint256) public votesReceived; // address to distribute to
    mapping(address => uint256) public contributions;
    mapping(address => uint256) public spentContributions;

    uint256 public threshold = 10 ether;
    bool public distributed = false;

    constructor() {
        owner = msg.sender;
    }

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
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        if (distributed) {
            revert AlreadyDistributed();
        }
        if (votesReceived[to] < threshold) {
            revert ThresholdNotMet();
        }
        // threshold met
        distributed = true;
        uint256 amount = address(this).balance;        
        // send funds
        (bool ok, ) = payable(address(to)).call{value: amount}("");
        require(ok, "ether transfer failed");
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
