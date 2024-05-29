// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {AdventureGoldGovernance} from "../src/AdventureGoldGovernance.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SimpleMintable} from "./SimpleMintable.sol";

contract AdventureGoldGovernanceTest is Test {
    AdventureGoldGovernance adventureGoldGovernance;
    IERC20 adventureGold;
    uint256 mainnetFork;
    address testingAddress = 0x6cC5F688a315f3dC28A7781717a9A798a59fDA7b;
    address testingAddress2 = 0xdd3767ABcAB26f261e2508A1DA1914053c7DDa78;

    /// @notice Error emitted when transfers are not to or from the contract.
    error OnlyTransfersToFromContract();

    /// @notice Error emitted when the transfer function is called
    error NonTransferable();

    /**
     * @dev Total supply cap has been exceeded, introducing a risk of votes overflowing.
     */
    error ERC20ExceededSafeSupply(uint256 increasedSupply, uint256 cap);

    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

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

    function test_CannotTransferExceptToOrFromContract() public {
        // 100 tokens (which uses 18 decimals)
        uint256 amount = 100 * 10 ** 18;

        // Deposit 100 AGLD tokens
        vm.startPrank(testingAddress);
        adventureGold.approve(address(adventureGoldGovernance), amount);
        adventureGoldGovernance.deposit(amount);

        // Give approvals for transferFrom
        adventureGoldGovernance.approve(testingAddress2, amount);
        adventureGoldGovernance.approve(address(adventureGoldGovernance), amount);

        // Try to transfer 100 Adventure Gold Governance tokens to another
        // address
        vm.startPrank(testingAddress);
        vm.expectRevert(NonTransferable.selector);
        adventureGoldGovernance.transfer(testingAddress2, amount);

        vm.expectRevert(NonTransferable.selector);
        adventureGoldGovernance.transferFrom(testingAddress, testingAddress2, amount);

        // Try to transfer 100 Adventure Gold Governance tokens to the contract
        vm.expectRevert(NonTransferable.selector);
        adventureGoldGovernance.transfer(address(adventureGoldGovernance), amount);

        vm.expectRevert(NonTransferable.selector);
        adventureGoldGovernance.transferFrom(testingAddress, address(adventureGoldGovernance), amount);

        // Try to transfer 100 Adventure Gold Governance tokens to the burn address
        vm.expectRevert(NonTransferable.selector);
        adventureGoldGovernance.transfer(address(adventureGoldGovernance), amount);

        vm.stopPrank();
    }

    function test_CannotDepositMoreThanBalance() public {
        // Starting balance of AGLD
        uint256 startingBalance = adventureGold.balanceOf(testingAddress2);

        // 100 tokens (which uses 18 decimals)
        uint256 amount = 100 * 10 ** 18;
        uint256 amountMoreThanBalance = 100_000_000 * 10 ** 18;

        // Deposit 100 AGLD tokens
        vm.startPrank(testingAddress2);
        adventureGold.approve(address(adventureGoldGovernance), amount);
        adventureGoldGovernance.deposit(amount);

        // Check balances after deposit
        assertEq(adventureGold.balanceOf(testingAddress2), startingBalance - amount);
        assertEq(adventureGoldGovernance.balanceOf(testingAddress2), amount);
        assertEq(adventureGoldGovernance.totalSupply(), amount);

        // Try to deposit an amount greater than the balance
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        adventureGoldGovernance.deposit(amountMoreThanBalance);

        // Check balances after failed deposit
        assertEq(adventureGold.balanceOf(testingAddress2), startingBalance - amount);
        assertEq(adventureGoldGovernance.balanceOf(testingAddress2), amount);
        assertEq(adventureGoldGovernance.totalSupply(), amount);

        vm.stopPrank();
    }

    function test_CannotWithdrawMoreThanBalance() public {
        // Starting balance of AGLD
        uint256 startingBalance = adventureGold.balanceOf(testingAddress2);

        // 100 tokens (which uses 18 decimals)
        uint256 amount = 100 * 10 ** 18;

        // Deposit 100 AGLD tokens
        vm.startPrank(testingAddress2);
        adventureGold.approve(address(adventureGoldGovernance), amount);
        adventureGoldGovernance.deposit(amount);

        // Check balances after deposit
        assertEq(adventureGold.balanceOf(testingAddress2), startingBalance - amount);
        assertEq(adventureGoldGovernance.balanceOf(testingAddress2), amount);
        assertEq(adventureGoldGovernance.totalSupply(), amount);

        // Try to withdraw an amount greater than the balance
        vm.expectRevert(abi.encodeWithSelector(ERC20InsufficientBalance.selector, testingAddress2, amount, amount + 1));
        adventureGoldGovernance.withdraw(amount + 1);

        // Check balances after failed withdrawal
        assertEq(adventureGold.balanceOf(testingAddress2), startingBalance - amount);
        assertEq(adventureGoldGovernance.balanceOf(testingAddress2), amount);
        assertEq(adventureGoldGovernance.totalSupply(), amount);

        vm.stopPrank();
    }

    function testDepositOverflowBehaviorERC20Votes() public {
        // Use vm.etch to replace Adventure Gold address with standard ERC-20 address
        SimpleMintable simpleMintable = new SimpleMintable();
        vm.etch(adventureGoldGovernance.AGLD_TOKEN_ADDRESS(), address(simpleMintable).code);
        simpleMintable = SimpleMintable(adventureGoldGovernance.AGLD_TOKEN_ADDRESS());

        address adventureGoldContractOwner = 0xcD814C83198C15A542F9A13FAf84D518d1744ED1;
        vm.startPrank(adventureGoldContractOwner);
        uint256 balanceToSend =
            (type(uint256).max - adventureGold.balanceOf(0xcD814C83198C15A542F9A13FAf84D518d1744ED1));
        simpleMintable.mint(balanceToSend);
        vm.expectRevert();
        simpleMintable.mint(1);
        assertEq(type(uint256).max, adventureGold.balanceOf(adventureGoldContractOwner));
        assertEq(0, adventureGoldGovernance.totalSupply());

        // Deposit uint256 max AGLD tokens
        adventureGold.approve(address(adventureGoldGovernance), type(uint256).max);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20ExceededSafeSupply.selector,
                115792089237316195423570985008687907853269984665640564039457584007913129639935,
                411376139330301510538742295639337626245683966408394965837152255
            )
        );
        adventureGoldGovernance.deposit(type(uint256).max);

        uint256 depositAmount = uint256(type(uint208).max);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20ExceededSafeSupply.selector,
                411376139330301510538742295639337626245683966408394965837152256,
                411376139330301510538742295639337626245683966408394965837152255
            )
        );
        adventureGoldGovernance.deposit(depositAmount + 1);

        // This should succeed when we only deposit the cap set by ERC20Votes
        adventureGoldGovernance.deposit(depositAmount);
    }

    function testOverflowBehaviorERC20() public {
        SimpleMintable simpleMintable = new SimpleMintable();
        simpleMintable.mint(type(uint256).max);
        // Uncomment this to trigger an overflow
        // simpleMintable.mint(1);
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
