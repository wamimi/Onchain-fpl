// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @notice Mock USDC token for testing purposes
 * @dev Implements standard ERC20 with 6 decimals to match real USDC
 */
contract MockUSDC is ERC20 {
    uint8 private constant DECIMALS = 6;

    constructor() ERC20("Mock USDC", "USDC") {
        // Mint 1 million USDC to deployer for testing
        _mint(msg.sender, 1_000_000 * 10**DECIMALS);
    }

    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /**
     * @notice Mint tokens for testing
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint (in USDC units with decimals)
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
