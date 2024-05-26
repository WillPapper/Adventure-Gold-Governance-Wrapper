// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {AdventureGoldGovernance} from "../src/AdventureGoldGovernance.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract AdventureGoldGovernanceTest is Test {
    AdventureGoldGovernance adventureGoldGovernance;
    IERC20 adventureGold;
    uint256 mainnetFork;
    address testingAddress = 0x6cC5F688a315f3dC28A7781717a9A798a59fDA7b;

    function setUp() public {
        mainnetFork = vm.createFork(vm.envString("ETHEREUM_MAINNET_RPC_URL"));
        vm.selectFork(mainnetFork);
        // Roll to a block number post AdventureGoldGovernance deployment
        vm.rollFork(19834161);
        adventureGoldGovernance = new AdventureGoldGovernance();
        adventureGold = IERC20(0x32353A6C91143bfd6C7d363B546e62a9A2489A20);
    }

    function test_AdventureGoldAddress() public {
        assertEq(adventureGoldGovernance.AGLD_TOKEN_ADDRESS(), 0x32353A6C91143bfd6C7d363B546e62a9A2489A20);
    }

    function test_DepositAndWithdraw() public {
        // Starting balance of AGLD
        uint256 startingBalance = adventureGold.balanceOf(testingAddress);
        // Starting balance of Adventure Gold Governance
        assertEq(adventureGoldGovernance.balanceOf(testingAddress), 0);
        assertEq(adventureGoldGovernance.totalSupply(), 0);

        // 100 tokens (which uses 18 decimals)
        uint256 amount = 100 * 10 ** 18;

        // Deposit 100 AGLD tokens
        vm.startPrank(testingAddress);
        adventureGold.approve(address(adventureGoldGovernance), amount);
        adventureGoldGovernance.deposit(amount);

        // Check balances after deposit
        assertEq(adventureGold.balanceOf(testingAddress), startingBalance - amount);
        assertEq(adventureGoldGovernance.balanceOf(testingAddress), amount);
        assertEq(adventureGoldGovernance.totalSupply(), amount);

        // Withdraw 100 AGLD tokens
        adventureGoldGovernance.withdraw(amount);

        // Check balances after withdrawal
        assertEq(adventureGold.balanceOf(testingAddress), startingBalance);
        assertEq(adventureGoldGovernance.balanceOf(testingAddress), 0);
        assertEq(adventureGoldGovernance.totalSupply(), 0);

        vm.stopPrank();
    }

    // This is a given in the AGLD contract, so it's not strictly necessary to
    // test
    function test_CannotDepositWithoutApprovals() public {
        // Starting balance of AGLD
        uint256 startingBalance = adventureGold.balanceOf(testingAddress);

        // 100 tokens (which uses 18 decimals)
        uint256 amount = 100 * 10 ** 18;

        // Deposit 100 AGLD tokens without approval
        vm.startPrank(testingAddress);
        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        adventureGoldGovernance.deposit(amount);

        // Check balances after deposit
        assertEq(adventureGold.balanceOf(testingAddress), startingBalance);
        assertEq(adventureGoldGovernance.balanceOf(testingAddress), 0);
        assertEq(adventureGoldGovernance.totalSupply(), 0);
    }
}
