 methods {
    // envfree functions 
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;
    function allowance(address,address) external returns uint256 envfree;
}

// Filter transfers because we have already confirmed that they are vacuous
definition filterTransfers(method f) returns bool = (f.selector !=
sig:transfer(address,uint256).selector && f.selector !=
sig:transferFrom(address,address,uint256).selector);

// Only surface transfers (to prove that they are vacuous)
definition onlyTransfers(method f) returns bool = (f.selector ==
sig:transfer(address,uint256).selector || f.selector ==
sig:transferFrom(address,address,uint256).selector);

/** @title Prove that transfers are vacuous because they always revert */
rule transfersAlwaysRevert(method f) filtered { f -> onlyTransfers(f) } {
    env e;
    calldataarg args;
    f@withrevert(e, args);

    assert (lastReverted, "transfer did not revert");
}

/** @title Users' balance can only be changed as a result of `deposit()` or
 * `withdraw()`
 *
 * @notice The use of `f.selector` in this rule is very similar to its use in solidity.
 * Since f is a parametric method that can be any function in the contract, we use
 * `f.selector` to specify the functions that may change the balance.
 */
rule balanceChangesFromCertainFunctions(method f, address user) filtered { f -> filterTransfers(f) } {
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

/** @title Users can never withdraw more than they've deposited 
*/
rule canNeverWithdrawMoreThanDeposited(method f, address user, uint256 depositAmount,
uint256 withdrawAmount) filtered { f -> filterTransfers(f) } {
    env e;
    calldataarg args;

    deposit(e, depositAmount);
    f(e, args);
    withdraw@withrevert(e, withdrawAmount);

    // Withdraw should revert if the user tries to withdraw more than they've
    // deposited. Otherwise, the withdrawal should proceed.
    assert(lastReverted || withdrawAmount <= depositAmount, "user withdrew more than deposited");
}