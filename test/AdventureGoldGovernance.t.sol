// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {AdventureGoldGovernance} from "../src/AdventureGoldGovernance.sol";

contract AdventureGoldGovernanceTest is Test {
    AdventureGoldGovernance adventureGoldGovernance;
    uint256 mainnetFork;

    function setUp() public {
        mainnetFork = vm.createFork("https://rpc.ankr.com/eth");
        vm.selectFork(mainnetFork);
        // Roll to a block number post AdventureGoldGovernance deployment
        vm.rollFork(19834161);
        adventureGoldGovernance = AdventureGoldGovernance(0x1b8e6AC31175d51Ee67540f3BF160CD21F51373c);
    }

    function test_AdventureGold_Address() public {
        assertEq(adventureGoldGovernance.AGLD_TOKEN_ADDRESS(), 0x32353A6C91143bfd6C7d363B546e62a9A2489A20);
    }
}
