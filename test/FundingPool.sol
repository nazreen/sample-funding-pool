// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {FundingPool} from "../src/FundingPool.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";              



contract FundingPoolTest is Test {
    using stdStorage for StdStorage;

    address user1 = address(1); // only votes
    address user2 = address(2); // only receives
    address outsiderUser = address(3);
    address deployer;

    FundingPool public fundingPool;

    function setUp() public {
        fundingPool = new FundingPool();
        deployer = msg.sender;
    }

    function bypassThreshold(address voteRecipient) internal {
        stdstore
            .target(address(fundingPool))
            .sig("votesReceived(address)")
            .with_key(voteRecipient)
            .checked_write(fundingPool.threshold());
    }

    function bypassOwner(address newOwner) internal {
        stdstore
            .target(address(fundingPool))
            .sig("owner()")
            .checked_write(newOwner);
    }

    function testFuzz_Contribute(uint256 x) public {
        vm.assume(x > 0);
        uint256 sendAmount = x;
        address sender = address(1);
        vm.deal(sender, sendAmount);
        vm.prank(sender);
        (bool ok, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok, "ether transfer failed");
        assertEq(fundingPool.contributions(sender), x);
    }

    function test_RecordsContributions() public {
        uint256 sendAmount = 1 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        (bool ok, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok, "ether transfer failed");
        assertEq(
            fundingPool.contributions(user1),
            sendAmount,
            "Ether received does not match the sent amount"
        );
    }

    function test_VotesCasted() public {
        //
        uint256 sendAmount = 1 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        (bool ok, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok, "ether transfer failed");
        assertGe(fundingPool.contributions(user1), 0);
        //

        //
        uint256 numToCast = sendAmount / 2;
        vm.prank(user1);
        fundingPool.vote(user2, numToCast);
        assertEq(fundingPool.votesReceived(user2), numToCast);
        assertEq(fundingPool.spentContributions(user1), numToCast);
        //
    }

    // user with 0 can't vote
    function test_CantVoteIfNoContributions() public {
        assertEq(fundingPool.contributions(outsiderUser), 0);
        vm.prank(outsiderUser);
        vm.expectRevert();
        fundingPool.vote(user2, 500);
    }

    // can't vote with more than contributions
    function test_CantVoteIfExceedingContributions() public {
        uint256 sendAmount = 1 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        (bool ok, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok, "ether transfer failed");

        uint256 numToCast = 2 ether;
        vm.prank(user1);
        vm.expectRevert();
        fundingPool.vote(user2, numToCast);
    }

    // can't vote with more than contributions - spentContributions
    function test_CantVoteIfExceedingUnspentContributions() public {
        uint256 sendAmount = 1 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        (bool ok, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok, "ether transfer failed");

        uint256 numToCast = 0.7 ether;
        vm.prank(user1);
        fundingPool.vote(user2, numToCast);

        uint256 numToCast2 = 0.5 ether;
        require((numToCast + numToCast2) > sendAmount, "Both amounts should exceed sendAmount for this test");
        vm.prank(user1);
        vm.expectRevert();
        fundingPool.vote(user2, numToCast2);
    }

    // TODO: figure out how to get the deployer address in this particular test
    // function test_recordsOwner() public {
    //     stdstore
    //         .target(address(fundingPool))
    //         .sig("owner()")
    //         .checked_write(deployer);
    //     assertEq(fundingPool.owner(), msg.sender);
    // }

    function test_notOwnerCannotDistribute() public {
        bypassThreshold(user2);
        assertNotEq(fundingPool.owner(), user1);
        vm.prank(user1);
        vm.expectRevert();
        fundingPool.distribute(user2);
    }
    
    function test_ownerCanDistribute() public {
        // mock the owner address
        bypassOwner(deployer);
        assertEq(fundingPool.owner(), deployer);
        // mock storage to surpass threshold
        bypassThreshold(user2);
        vm.prank(deployer);
        fundingPool.distribute(user2);
    }

    // cant distribute if threshold not met
    function test_CantDistributeIfThresholdNotMet() public {
        bypassOwner(user1);
        uint256 sendAmount = 1 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        (bool ok, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok, "ether transfer failed");
        assertEq(fundingPool.contributions(user1), sendAmount);
        vm.prank(user1);
        vm.expectRevert();
        fundingPool.distribute(user2);
    }

    // cant distribute if already distributed
    function test_CantDistributeIfAlreadyDistributed() public {
        bypassOwner(user1);
        uint256 sendAmount = 10 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        (bool ok, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok, "ether transfer failed");
        assertEq(fundingPool.contributions(user1), sendAmount);
        vm.prank(user1);
        fundingPool.vote(user2, sendAmount);
        vm.prank(user1);
        fundingPool.distribute(user2);
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        (bool ok2, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok2, "ether transfer failed");
        vm.prank(user1);
        vm.expectRevert();
        fundingPool.distribute(user2);
    }

    // sends ether balance to user
    function test_Distribute() public {
        bypassOwner(user1);
        uint256 sendAmount = 10 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        (bool ok, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok, "ether transfer failed");
        assertEq(fundingPool.contributions(user1), sendAmount);
        vm.prank(user1);
        fundingPool.vote(user2, sendAmount);
        vm.prank(user1);
        fundingPool.distribute(user2);
        assertEq(user2.balance, sendAmount);
    }

}
