// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {FundingPool} from "../src/FundingPool.sol";

contract FundingPoolScript is Script {
    function setUp() public {}

    function run() public returns (FundingPool) {
        vm.startBroadcast();

        FundingPool fundingPool = new FundingPool();
        
        vm.stopBroadcast();
        return fundingPool;
    }
}