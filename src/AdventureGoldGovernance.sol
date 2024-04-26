// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../lib/openzeppelin-contracts/contracts/interfaces/IERC6372.sol";
import "../lib/openzeppelin-contracts/contracts/governance/utils/Votes.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SpitToken is ERC20Burnable, IERC6372, ERC20Permit, ERC20Votes {
    using SafeERC20 for IERC20;

    error OnlyOwner();
    error SupplyLimitReached();
    error MintPaused();
    error OnlyTransfersToFromContract();

    uint256 public constant SUPPLY_CAP = 1000000000e18;
    address public immutable OWNER;
    address public immutable AGLD_TOKEN_ADDRESS = 0x32353A6C91143bfd6C7d363B546e62a9A2489A20;
    IERC20 public immutable AGLD = IERC20(AGLD_TOKEN_ADDRESS);

    bool public paused;

    modifier onlyOwner() {
        if (msg.sender != OWNER) revert OnlyOwner();
        _;
    }

    constructor() ERC20("Adventure Gold Governance", "AGLDGOV") ERC20Permit("Adventure Gold Governance") {
        OWNER = msg.sender;
    }

    // Allows anyone to deposit AGLD tokens and receive Adventure Gold
    // Governance tokens in return
    function deposit(uint256 amount) external {
        // Follows the Checks-Effects-Interactions pattern
        // Checks
        // Allowance and transfer checks occur in the AGLD token contract

        // Effects
        // Mint the same amount of Adventure Gold Governance tokens
        _mint(msg.sender, amount);

        // Interactions
        // Transfer AGLD tokens from the sender to this contract
        AGLD.safeTransferFrom(msg.sender, address(this), amount);
    }

    // Allows anyone to burn Adventure Gold Governance tokens and receive AGLD
    // tokens in return
    function withdraw(uint256 amount) external {
        // Follows the Checks-Effects-Interactions pattern
        // Checks
        // Allowance checks occur in `burnFrom` via `_spendAllowance`

        // Effects
        // Burn the same amount of Adventure Gold Governance tokens
        burnFrom(msg.sender, amount);

        // Interactions
        // Transfer AGLD tokens from this contract to the sender
        AGLD.safeTransfer(msg.sender, amount);
    }

    // TODO Override the _beforeTokenTransfer function to prevent transfers.
    // Only transfers to/from this contract are allowed
    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Votes) {
        if (from != address(this) || to != address(this)) revert OnlyTransfersToFromContract();
        super._update(from, to, value);
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
