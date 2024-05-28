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
// This is groundwork so that we can filter transfers in later rules
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
// First, we confirm that only the deposit and withdraw functions will change
// user balances
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

// Then, we confirm that deposits alway increment the balance properly
rule balanceAlwaysIncrementsByDepositAmount(uint256 depositAmount) {
    env e;
    calldataarg args;

    mathint userBalanceBefore = balanceOf(e.msg.sender);
    deposit(e, depositAmount);
    mathint userBalanceAfter = balanceOf(e.msg.sender);

    assert(userBalanceBefore + to_mathint(depositAmount) == userBalanceAfter, "balance change different from deposit amount");
}


// Then, we confirm that withdrawals always decrement the balance properly
rule balanceAlwaysDecementsByWithdrawAmount(uint256 withdrawAmount) {
    env e;
    calldataarg args;

    mathint userBalanceBefore = balanceOf(e.msg.sender);
    // We immediately get the value of lastReverted because lastReverted updates
    // after every function call, not just @withrevert function calls
    withdraw(e, withdrawAmount);
    mathint userBalanceAfter = balanceOf(e.msg.sender);

    assert(userBalanceBefore - to_mathint(withdrawAmount) == userBalanceAfter, "balance change different from deposit amount");
}

/** @title Users can never withdraw more than they've deposited 
/* @dev We filter deposits and withdrawals here so that additional deposits and
 * withdrawals don't change the state
*/
// Then, we confirm that users can never withdraw more than they've deposited.
// This is very important for obvious reasons
// We filter additional deposit and withdrawal calls here because they do change
// the balance arbitrarily. We rely on the prior rules to know that
// incrementing/decrementing is happening properly
rule userCanNeverWithdrawMoreThanDeposited(method f, uint256 depositAmount,
uint256 withdrawAmount) filtered { f -> !adventureGoldGovernanceTransfers(f) && !adventureGoldGovernanceDepositsAndWithdrawals(f) } {
    env e;
    calldataarg args;

    mathint adventureGoldBalanceBefore = adventureGold.balanceOf(e.msg.sender);
    mathint adventureGoldGovernanceBalanceBefore = balanceOf(e.msg.sender);
    // This is separately verified in userCanNeverDepositMoreThanBalance
    require adventureGoldBalanceBefore >= to_mathint(depositAmount);

    deposit(e, depositAmount);
    f(e, args);
    withdraw(e, withdrawAmount);

    // Withdraw should revert if the user tries to withdraw more than they've
    // deposited. Otherwise, the withdrawal should proceed.
    assert(to_mathint(withdrawAmount) <= to_mathint(depositAmount) + adventureGoldGovernanceBalanceBefore, "user withdrew more than deposited");
}

// Only msg.sender can withdraw