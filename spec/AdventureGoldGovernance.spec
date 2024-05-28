 import "./helpers/erc20.spec";

 using ERC20Basic as adventureGold;

 methods {
    // envfree functions 
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;
    function allowance(address,address) external returns uint256 envfree;

    // DummyERC20Impl envfree functions
    function ERC20Basic.totalSupply() external returns uint256 envfree;
    function ERC20Basic.balanceOf(address) external returns uint256 envfree;
    function ERC20Basic.allowance(address,address) external returns uint256 envfree;

    // Dispatch for calls made through Address.sol. This ensures that low-level
    // calls will succeed
    function _._ external => DISPATCH [
        _.transferFrom(address, address, uint256),
        _.transfer(address, uint256)
    ] default NONDET;
}

// Only surface Adventure Gold Governance transfers (useful to prove that they
// are vacuous)
// Negate this to filter for everything besides Adventure Gold Governance transfers
definition adventureGoldGovernanceTransfers(method f) returns bool = (f.contract == currentContract &&
(f.selector ==
sig:transfer(address,uint256).selector || f.selector ==
sig:transferFrom(address,address,uint256).selector));

// Filter deposits and withdrawals (useful when testing arbitrary state changes
// besides deposits and withdrawals)
definition adventureGoldGovernanceDepositsAndWithdrawals(method f) returns bool = (f.contract == currentContract &&
(f.selector ==
sig:deposit(uint256).selector || f.selector ==
sig:withdraw(uint256).selector));

/** @title Prove that transfers are vacuous because they always revert */
rule transfersAlwaysRevert(method f) filtered { f -> adventureGoldGovernanceTransfers(f) } {
    env e;
    calldataarg args;
    f@withrevert(e, args);

    assert(lastReverted, "transfer did not revert");
}

/** @title Users' balance can only be changed as a result of `deposit()` or
 * `withdraw()`
 *
 * @notice The use of `f.selector` in this rule is very similar to its use in solidity.
 * Since f is a parametric method that can be any function in the contract, we use
 * `f.selector` to specify the functions that may change the balance.
 */
rule balanceChangesFromCertainFunctions(method f, address user) filtered { f -> !adventureGoldGovernanceTransfers(f) } {
    env e;
    calldataarg args;

    uint256 userBalanceBefore = balanceOf(user);
    f(e, args);
    uint256 userBalanceAfter = balanceOf(user);

    assert (
        userBalanceBefore != userBalanceAfter => 
        (
            f.selector == sig:deposit(uint256).selector ||
            f.selector == sig:withdraw(uint256).selector)
        ),
        "user's balance changed as a result function other than deposit() or withdraw()";
}

rule balanceAlwaysChangesByDepositAmount(method f, uint256 depositAmount) filtered { f -> !adventureGoldGovernanceTransfers(f) } {
    env e;
    calldataarg args;

    uint256 userBalanceBefore = balanceOf(e.msg.sender);
    deposit@withrevert(e, depositAmount);
    bool depositRevert = lastReverted;
    uint256 userBalanceAfter = balanceOf(e.msg.sender);

    assert(depositRevert || (userBalanceBefore + depositAmount) == to_mathint(userBalanceAfter), "balance change different from deposit amount");
}

/** @title Users can never withdraw more than they've deposited 
/* @dev We filter deposits and withdrawals here so that additional deposits and
 * withdrawals don't change the state
*/
rule userCanNeverWithdrawMoreThanDeposited(method f, uint256 depositAmount,
uint256 withdrawAmount) filtered { f -> !adventureGoldGovernanceTransfers(f) && !adventureGoldGovernanceDepositsAndWithdrawals(f) } {
    env e;
    calldataarg args;

    uint256 adventureGoldBalanceBefore = adventureGold.balanceOf(e.msg.sender);
    // This is separately verified in userCanNeverDepositMoreThanBalance
    require adventureGoldBalanceBefore >= depositAmount;

    deposit(e, depositAmount);
    f(e, args);
    withdraw@withrevert(e, withdrawAmount);

    // Withdraw should revert if the user tries to withdraw more than they've
    // deposited. Otherwise, the withdrawal should proceed.
    assert(lastReverted || withdrawAmount <= depositAmount, "user withdrew more than deposited");
}

// Only msg.sender can withdraw