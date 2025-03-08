// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

// NOTE: This contract should not be used for Production as it is for educational purposes only.

error NoZeroValue();
error InsufficientUnspentContributions();
error ThresholdNotMet();
error PotAlreadyDistributed();
error Unauthorized();
error PotNotFound();
error PotExpired();
error InvalidPotConfiguration();

contract FundingPool {
    event PotCreated(uint256 indexed potId, string name, uint256 threshold, uint256 expiryTime);
    event ContributionReceived(uint256 indexed potId, address indexed contributor, uint256 amount);
    event VoteCasted(uint256 indexed potId, address indexed voter, address indexed recipient, uint256 numCasted);
    event Distribution(uint256 indexed potId, address indexed to, uint256 amount);
    
    struct Pot {
        string name;
        uint256 threshold;
        uint256 totalContributions;
        uint256 expiryTime;
        bool distributed;
        mapping(address => uint256) votesReceived;
        mapping(address => uint256) contributions;
        mapping(address => uint256) spentContributions;
    }
    
    address public owner;
    uint256 public potCounter;
    
    // potId => Pot
    mapping(uint256 => Pot) public pots;
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Create a new funding pot
     * @param name Name of the pot
     * @param threshold Minimum votes required for distribution (in wei)
     * @param duration Duration in seconds for how long the pot is active
     * @return potId The ID of the newly created pot
     */
    function createPot(string memory name, uint256 threshold, uint256 duration) public returns (uint256) {
        if (threshold == 0) revert InvalidPotConfiguration();
        if (duration == 0) revert InvalidPotConfiguration();
        
        uint256 potId = potCounter++;
        Pot storage pot = pots[potId];
        pot.name = name;
        pot.threshold = threshold;
        pot.expiryTime = block.timestamp + duration;
        pot.distributed = false;
        
        emit PotCreated(potId, name, threshold, pot.expiryTime);
        return potId;
    }
    
    /**
     * @dev Contribute funds to a specific pot
     * @param potId ID of the pot to contribute to
     */
    function contribute(uint256 potId) public payable {
        if (msg.value == 0) revert NoZeroValue();
        Pot storage pot = pots[potId];
        if (pot.threshold == 0) revert PotNotFound();
        if (block.timestamp > pot.expiryTime) revert PotExpired();
        if (pot.distributed) revert PotAlreadyDistributed();
        
        pot.contributions[msg.sender] += msg.value;
        pot.totalContributions += msg.value;
        
        emit ContributionReceived(potId, msg.sender, msg.value);
    }
    
    /**
     * @dev Vote for a recipient in a specific pot
     * @param potId ID of the pot to vote in
     * @param voteRecipient Address that will receive the votes
     * @param numToCast Number of votes to cast
     */
    function vote(uint256 potId, address voteRecipient, uint256 numToCast) public {
        Pot storage pot = pots[potId];
        if (pot.threshold == 0) revert PotNotFound();
        if (block.timestamp > pot.expiryTime) revert PotExpired();
        if (pot.distributed) revert PotAlreadyDistributed();
        
        // check has sufficient contributions
        uint256 unspentContributions = pot.contributions[msg.sender] - pot.spentContributions[msg.sender];
        if (unspentContributions < numToCast) {
            revert InsufficientUnspentContributions();
        }
        
        pot.votesReceived[voteRecipient] += numToCast;
        pot.spentContributions[msg.sender] += numToCast;
        
        emit VoteCasted(potId, msg.sender, voteRecipient, numToCast);
    }
    
    /**
     * @dev Distribute funds from a pot to a recipient
     * @param potId ID of the pot to distribute
     * @param to Address to receive the funds
     */
    function distribute(uint256 potId, address to) public {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        
        Pot storage pot = pots[potId];
        if (pot.threshold == 0) revert PotNotFound();
        if (pot.distributed) {
            revert PotAlreadyDistributed();
        }
        if (pot.votesReceived[to] < pot.threshold) {
            revert ThresholdNotMet();
        }
        
        // Mark pot as distributed
        pot.distributed = true;
        
        // Calculate amount to send (all contributions to this pot)
        uint256 amount = pot.totalContributions;
        
        // Send funds
        (bool ok, ) = payable(address(to)).call{value: amount}("");
        require(ok, "ether transfer failed");
        
        emit Distribution(potId, to, amount);
    }
    
    /**
     * @dev Check votes received by a potential recipient
     * @param potId ID of the pot
     * @param recipient Address to check votes for
     * @return Number of votes received
     */
    function getVotesReceived(uint256 potId, address recipient) public view returns (uint256) {
        return pots[potId].votesReceived[recipient];
    }
    
    /**
     * @dev Check contributions made by a contributor
     * @param potId ID of the pot
     * @param contributor Address of the contributor
     * @return Amount contributed
     */
    function getContributions(uint256 potId, address contributor) public view returns (uint256) {
        return pots[potId].contributions[contributor];
    }
    
    /**
     * @dev Check spent contributions by a contributor
     * @param potId ID of the pot
     * @param contributor Address of the contributor
     * @return Amount of contributions spent on voting
     */
    function getSpentContributions(uint256 potId, address contributor) public view returns (uint256) {
        return pots[potId].spentContributions[contributor];
    }
    
    /**
     * @dev Check if a pot has been distributed
     * @param potId ID of the pot
     * @return Distribution status
     */
    function isPotDistributed(uint256 potId) public view returns (bool) {
        return pots[potId].distributed;
    }
    
    /**
     * @dev Get pot details
     * @param potId ID of the pot
     * @return name Name of the pot
     * @return threshold Threshold for distribution
     * @return totalContributions Total amount contributed
     * @return expiryTime Time when pot expires
     * @return distributed Whether pot has been distributed
     */
    function getPotDetails(uint256 potId) public view returns (
        string memory name,
        uint256 threshold,
        uint256 totalContributions,
        uint256 expiryTime,
        bool distributed
    ) {
        Pot storage pot = pots[potId];
        return (
            pot.name,
            pot.threshold,
            pot.totalContributions,
            pot.expiryTime,
            pot.distributed
        );
    }
}