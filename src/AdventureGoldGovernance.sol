// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC6372.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Adventure Gold Governance
/// @author Will Papper
/// @notice This contract allows users to deposit AGLD tokens and receive
/// Adventure Gold Governance tokens in return.
/// Users can also burn Adventure Gold Governance tokens to withdraw AGLD tokens.
/// @dev The contract inherits from ERC20Burnable, ERC20Permit, and ERC20Votes.
contract AdventureGoldGovernance is IERC6372, ERC20Permit, ERC20Votes {
    /// @notice Error emitted when transfers are not to or from the contract or
    /// the burn address
    error OnlyMintsAndBurnsAllowed();

    /// @notice Error emitted when the transfer function is called
    error NonTransferable();

    /// @notice Error emitted when a deposit or withdrawal of 0 is called
    error AmountMustBeGreaterThanZero();

    /// @notice Emitted when a user deposits AGLD tokens, minting Adventure Gold
    /// Governance tokens.
    /// @param user The address of the user who deposited tokens.
    /// @param amount The amount of AGLD tokens deposited.
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws AGLD tokens, burning Adventure
    /// Gold Governance tokens.
    /// @param user The address of the user who withdrew tokens.
    /// @param amount The amount of AGLD tokens withdrawn.
    event Withdrawal(address indexed user, uint256 amount);

    /// @notice The address of the AGLD token contract.
    address public immutable AGLD_TOKEN_ADDRESS = 0x32353A6C91143bfd6C7d363B546e62a9A2489A20;
    /// @notice The AGLD token contract.
    IERC20 public immutable AGLD_TOKEN = IERC20(AGLD_TOKEN_ADDRESS);

    /// @notice Constructor for the Adventure Gold Governance contract.
    constructor() ERC20("Adventure Gold Governance", "AGLDGOV") ERC20Permit("Adventure Gold Governance") {}

    /// @notice Deposits AGLD tokens and mints Adventure Gold Governance tokens in return.
    /// @param amount The amount of AGLD tokens to deposit.
    /// @dev Users must approve this contract to spend their AGLD tokens prior
    /// to depositing.
    /// @dev The AGLD tokens are transferred from the msg.sender to this contract.
    function deposit(uint256 amount) external {
        // Follows the Checks-Effects-Interactions pattern
        // Checks
        // Allowance and transfer checks occur in the AGLD token contract
        if (amount == 0) {
            revert AmountMustBeGreaterThanZero();
        }

        // Effects
        // Mint the same amount of Adventure Gold Governance tokens
        _mint(msg.sender, amount);

        // Interactions
        // Transfer AGLD tokens from the sender to this contract
        AGLD_TOKEN.transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount);
    }

    /// @notice Burns Adventure Gold Governance tokens and withdraws AGLD tokens in return.
    /// @param amount The amount of Adventure Gold Governance tokens to burn.
    /// @dev The Adventure Gold Governance tokens are burned from the msg.sender
    /// and the AGLD tokens are transferred to the msg.sender.
    function withdraw(uint256 amount) external {
        // Follows the Checks-Effects-Interactions pattern
        // Checks
        // No balance checks are needed since withdrawing more than the balance
        // triggers ERC20InsufficientBalance in the _burn() function
        // No allowance checks are needed since the msg.sender's tokens are
        // burned
        if (amount == 0) {
            revert AmountMustBeGreaterThanZero();
        }

        // Effects
        // Burn the same amount of Adventure Gold Governance tokens from the
        // sender
        _burn(msg.sender, amount);

        // Interactions
        // Transfer AGLD tokens from this contract to the sender
        AGLD_TOKEN.transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);
    }

    function transfer(address to, uint256 value) public override(ERC20) returns (bool) {
        revert NonTransferable();
    }

    function transferFrom(address from, address to, uint256 value) public override(ERC20) returns (bool) {
        revert NonTransferable();
    }

    /// @dev For Solidity lineraization, see https://medium.com/@kalexotsu/inheritance-inheritance-order-and-the-super-keyword-in-solidity-bbe49a2478b6
    /// @dev ERC20Votes is called since Solidity inheritance is linearized from right to left
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /// @notice Overrides IERC6372 functions to make the token & governor timestamp-based
    function clock() public view override(IERC6372, Votes) returns (uint48) {
        return uint48(block.timestamp);
    }

    /// @notice Returns the clock mode as "mode=timestamp".
    /// @return The clock mode string.
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override(IERC6372, Votes) returns (string memory) {
        return "mode=timestamp";
    }

    /// @notice Returns the nonce of an owner.
    /// @param owner The address of the owner.
    /// @return Nonce value.
    // The functions below are overrides required by Solidity.
    // Without it, you will receive the following error:
    // `Error (6480): Derived contract must override function "nonces". Two or
    // more base classes define function with same name and parameter types.`
    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
