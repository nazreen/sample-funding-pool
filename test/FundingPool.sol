// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {FundingPool} from "../src/FundingPool.sol";


contract FundingPoolTest is Test {
    address user1 = address(1); // only votes
    address user2 = address(2); // only receives
    address outsiderUser = address(3);

    FundingPool public fundingPool;

    function setUp() public {
        fundingPool = new FundingPool();
    }

    // function testFuzz_Contribute(uint256 x) public {
    //     uint256 sendAmount = x;
    //     address sender = address(1); // In this test, the sender is the test contract itself
    //     vm.prank(address(1));
    //     payable(address(fundingPool)).transfer(sendAmount);
    //     assertEq(fundingPool.contributions(sender), x);
    // }

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

    // can't contribute more than 10 ether per address
    function test_CantContributeMoreThan10Ether() public {
        uint256 sendAmount = 11 ether;
        vm.deal(user1, sendAmount);
        vm.prank(user1);
        vm.expectRevert();
        (bool ok, ) = payable(address(fundingPool)).call{value: sendAmount}("");
        require(ok, "ether transfer failed");
    }

    // can't vote more than 10 ether per address
}
