 methods {
    // envfree functions 
    function totalSupply() external returns uint256 envfree;
    function balanceOf(address) external returns uint256 envfree;
    function allowance(address,address) external returns uint256 envfree;
}

rule simpleMintableAlwaysIncrementsByMintAmount(uint256 amount) {
    env e;
    mathint balanceBefore = totalSupply();

    mint(e, amount);

    mathint balanceAfter = totalSupply();

    assert(balanceAfter - amount == balanceBefore, "balance did not increase by mint amount");
}
