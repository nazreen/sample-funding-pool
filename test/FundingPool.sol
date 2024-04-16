// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {FundingPool} from "../src/FundingPool.sol";

contract FundingPoolTest is Test {
    FundingPool public fundingPool;

    function setUp() public {
        fundingPool = new FundingPool();
        fundingPool.setNumber(0);
    }

    function test_Increment() public {
        fundingPool.increment();
        assertEq(fundingPool.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        fundingPool.setNumber(x);
        assertEq(fundingPool.number(), x);
    }
}
