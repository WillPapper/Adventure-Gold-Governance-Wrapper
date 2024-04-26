// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../lib/openzeppelin-contracts/contracts/interfaces/IERC6372.sol";
import "../lib/openzeppelin-contracts/contracts/governance/utils/Votes.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract SpitToken is ERC20, IERC6372, ERC20Permit, ERC20Votes {
    error OnlyOwner();
    error SupplyLimitReached();
    error MintPaused();

    uint256 public constant SUPPLY_CAP = 1000000000e18;
    address public immutable OWNER;

    bool public paused;

    modifier onlyOwner() {
        if (msg.sender != OWNER) revert OnlyOwner();
        _;
    }

    constructor() ERC20("Spit", "SPIT") ERC20Permit("Spit") {
        OWNER = msg.sender;
    }

    // Overrides IERC6372 functions to make the token & governor timestamp-based
    function clock() public view override(IERC6372, Votes) returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override(IERC6372, Votes) returns (string memory) {
        return "mode=timestamp";
    }

    // The functions below are overrides required by Solidity.

    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function mint(address dest, uint256 amount) external {
        if (paused) revert MintPaused();
        if (totalSupply() + amount > SUPPLY_CAP) revert SupplyLimitReached();
        _update(address(0), dest, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _update(account, address(0), amount);
    }

    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
    }
}
