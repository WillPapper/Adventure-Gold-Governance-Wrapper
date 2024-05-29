// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract SimpleMintable is ERC20 {
    constructor() ERC20("Simple Mintable", "SIMPLE") {}

    function mint(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}
