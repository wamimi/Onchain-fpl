// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PrizeDistributor
 * @notice Library for calculating and validating prize distributions
 * @dev Used by League contract to handle prize pool mathematics
 */
library PrizeDistributor {
    // Errors
    error InvalidDistribution();
    error InvalidPrizePool();
    error EmptyWinnersList();
    error DistributionExceedsPrizePool();

    /**
     * @notice Calculate individual prize amounts based on total pool and distribution percentages
     * @param prizePool Total USDC in the prize pool
     * @param distribution Array of percentages (e.g., [60, 30, 10])
     * @return prizes Array of prize amounts in USDC
     */
    function calculatePrizes(uint256 prizePool, uint256[] memory distribution)
        internal
        pure
        returns (uint256[] memory)
    {
        if (prizePool == 0) revert InvalidPrizePool();
        if (distribution.length == 0) revert InvalidDistribution();

        uint256[] memory prizes = new uint256[](distribution.length);
        uint256 totalAllocated = 0;

        for (uint256 i = 0; i < distribution.length; i++) {
            uint256 prizeAmount = (prizePool * distribution[i]) / 100;
            prizes[i] = prizeAmount;
            totalAllocated += prizeAmount;
        }

        // Ensure we don't exceed prize pool (rounding errors)
        if (totalAllocated > prizePool) revert DistributionExceedsPrizePool();

        return prizes;
    }

    /**
     * @notice Validate that prize distribution percentages sum to 100
     * @param distribution Array of percentages
     * @return valid True if distribution is valid
     */
    function validateDistribution(uint256[] memory distribution) internal pure returns (bool) {
        if (distribution.length == 0) return false;

        uint256 total = 0;
        for (uint256 i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) return false; // No zero percentages
            total += distribution[i];
        }

        return total == 100;
    }

    /**
     * @notice Calculate total prize for a specific position
     * @param prizePool Total USDC in the prize pool
     * @param percentage Percentage for this position (e.g., 60 for first place)
     * @return prize Prize amount in USDC
     */
    function calculateSinglePrize(uint256 prizePool, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (prizePool == 0) revert InvalidPrizePool();
        if (percentage == 0 || percentage > 100) revert InvalidDistribution();

        return (prizePool * percentage) / 100;
    }

    /**
     * @notice Distribute prizes to winners (validation only, actual transfer done by caller)
     * @param winners Array of winner addresses
     * @param amounts Array of prize amounts
     * @return valid True if distribution is valid
     */
    function validatePrizeDistribution(address[] memory winners, uint256[] memory amounts)
        internal
        pure
        returns (bool)
    {
        if (winners.length == 0) revert EmptyWinnersList();
        if (winners.length != amounts.length) return false;

        // Validate no zero addresses
        for (uint256 i = 0; i < winners.length; i++) {
            if (winners[i] == address(0)) return false;
            if (amounts[i] == 0) return false;
        }

        return true;
    }

    /**
     * @notice Get winner count based on distribution length and participant count
     * @param distributionLength Number of prize tiers
     * @param participantCount Number of participants
     * @return winnerCount Actual number of winners (limited by participants)
     */
    function getWinnerCount(uint256 distributionLength, uint256 participantCount)
        internal
        pure
        returns (uint256)
    {
        return distributionLength > participantCount ? participantCount : distributionLength;
    }
}
