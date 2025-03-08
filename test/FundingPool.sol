// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {FundingPool} from "../src/FundingPool.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";              

contract FundingPoolTest is Test {
    using stdStorage for StdStorage;

    address user1 = address(1); // contributor and voter
    address user2 = address(2); // recipient
    address user3 = address(3); // another contributor
    address deployer;

    FundingPool public fundingPool;
    uint256 public potId;
    uint256 public defaultThreshold = 10 ether;
    uint256 public defaultDuration = 7 days;

    function setUp() public {
        fundingPool = new FundingPool();
        deployer = address(this);
        // Create a default pot for testing
        potId = fundingPool.createPot("Test Pot", defaultThreshold, defaultDuration);
    }

    function test_CreatePot() public {
        string memory potName = "New Test Pot";
        uint256 threshold = 5 ether;
        uint256 duration = 3 days;
        
        uint256 newPotId = fundingPool.createPot(potName, threshold, duration);
        
        (string memory name, uint256 potThreshold, , uint256 expiryTime, bool distributed) = fundingPool.getPotDetails(newPotId);
        
        assertEq(name, potName);
        assertEq(potThreshold, threshold);
        assertEq(expiryTime, block.timestamp + duration);
        assertEq(distributed, false);
    }

    function testFuzz_Contribute(uint256 x) public {
        vm.assume(x > 0 && x < 100 ether); // Reasonable bounds
        
        vm.deal(user1, x);
        vm.prank(user1);
        fundingPool.contribute{value: x}(potId);
        
        assertEq(fundingPool.getContributions(potId, user1), x);
    }

    function test_ContributeToPot() public {
        uint256 sendAmount = 1 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount}(potId);
        
        assertEq(
            fundingPool.getContributions(potId, user1),
            sendAmount,
            "Ether received does not match the sent amount"
        );
    }

    function test_VotesCasted() public {
        uint256 sendAmount = 1 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount}(potId);
        
        uint256 numToCast = sendAmount / 2;
        vm.prank(user1);
        fundingPool.vote(potId, user2, numToCast);
        
        assertEq(fundingPool.getVotesReceived(potId, user2), numToCast);
        assertEq(fundingPool.getSpentContributions(potId, user1), numToCast);
    }

    function test_CantVoteIfNoContributions() public {
        vm.prank(user3);
        vm.expectRevert();
        fundingPool.vote(potId, user2, 500);
    }

    function test_CantVoteIfExceedingContributions() public {
        uint256 sendAmount = 1 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount}(potId);

        uint256 numToCast = 2 ether;
        vm.prank(user1);
        vm.expectRevert();
        fundingPool.vote(potId, user2, numToCast);
    }

    function test_CantVoteIfExceedingUnspentContributions() public {
        uint256 sendAmount = 1 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount}(potId);

        uint256 numToCast = 0.7 ether;
        vm.prank(user1);
        fundingPool.vote(potId, user2, numToCast);

        uint256 numToCast2 = 0.5 ether;
        require((numToCast + numToCast2) > sendAmount, "Both amounts should exceed sendAmount for this test");
        vm.prank(user1);
        vm.expectRevert();
        fundingPool.vote(potId, user2, numToCast2);
    }

    function test_notOwnerCannotDistribute() public {
        // Setup
        uint256 sendAmount = defaultThreshold;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount}(potId);
        
        vm.prank(user1);
        fundingPool.vote(potId, user2, sendAmount);
        
        // Non-owner tries to distribute
        vm.prank(user1);
        vm.expectRevert();
        fundingPool.distribute(potId, user2);
    }
    
    function test_ownerCanDistribute() public {
        // Setup
        uint256 sendAmount = defaultThreshold;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount}(potId);
        
        vm.prank(user1);
        fundingPool.vote(potId, user2, sendAmount);
        
        // Owner distributes
        fundingPool.distribute(potId, user2);
        
        // Check pot is marked as distributed
        assertTrue(fundingPool.isPotDistributed(potId));
    }

    function test_CantDistributeIfThresholdNotMet() public {
        uint256 sendAmount = defaultThreshold / 2;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount}(potId);
        
        vm.prank(user1);
        fundingPool.vote(potId, user2, sendAmount);

        vm.expectRevert();
        fundingPool.distribute(potId, user2);
    }

    function test_CantDistributeIfAlreadyDistributed() public {
        // First distribution
        uint256 sendAmount = defaultThreshold;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount}(potId);
        
        vm.prank(user1);
        fundingPool.vote(potId, user2, sendAmount);
        
        fundingPool.distribute(potId, user2);
        
        // Try second distribution
        vm.expectRevert();
        fundingPool.distribute(potId, user2);
    }

    function test_MultiplePots() public {
        // Create two pots
        uint256 pot1 = potId; // Use existing pot
        uint256 pot2 = fundingPool.createPot("Second Pot", 5 ether, 30 days);
        
        // Contribute to both pots
        uint256 sendAmount1 = 10 ether;
        uint256 sendAmount2 = 5 ether;
        
        vm.deal(user1, sendAmount1 + sendAmount2);
        
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount1}(pot1);
        
        vm.prank(user1);
        fundingPool.contribute{value: sendAmount2}(pot2);
        
        // Vote in both pots
        vm.prank(user1);
        fundingPool.vote(pot1, user2, sendAmount1);
        
        vm.prank(user1);
        fundingPool.vote(pot2, user3, sendAmount2);
        
        // Distribute pot1 
        fundingPool.distribute(pot1, user2);
        
        // Check pot1 distributed but pot2 not
        assertTrue(fundingPool.isPotDistributed(pot1));
        assertFalse(fundingPool.isPotDistributed(pot2));
        
        // Distribute pot2
        fundingPool.distribute(pot2, user3);
        assertTrue(fundingPool.isPotDistributed(pot2));
    }

    function test_ExpiredPot() public {
        // Create a pot with very short duration
        uint256 shortPotId = fundingPool.createPot("Short Pot", 5 ether, 1 hours);
        
        // Fast forward beyond expiry
        vm.warp(block.timestamp + 2 hours);
        
        // Try to contribute
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        vm.expectRevert();
        fundingPool.contribute{value: 1 ether}(shortPotId);
    }
}