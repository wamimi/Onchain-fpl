// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PrizeDistributor.sol";

// Helper contract to test library reverts
contract PrizeDistributorWrapper {
    function calculatePrizes(uint256 prizePool, uint256[] memory distribution)
        external
        pure
        returns (uint256[] memory)
    {
        return PrizeDistributor.calculatePrizes(prizePool, distribution);
    }

    function calculateSinglePrize(uint256 prizePool, uint256 percentage)
        external
        pure
        returns (uint256)
    {
        return PrizeDistributor.calculateSinglePrize(prizePool, percentage);
    }

    function validatePrizeDistribution(address[] memory winners, uint256[] memory amounts)
        external
        pure
        returns (bool)
    {
        return PrizeDistributor.validatePrizeDistribution(winners, amounts);
    }
}

contract PrizeDistributorTest is Test {
    using PrizeDistributor for *;

    PrizeDistributorWrapper wrapper;

    function setUp() public {
        wrapper = new PrizeDistributorWrapper();
    }

    /*//////////////////////////////////////////////////////////////
                      CALCULATE PRIZES TESTS
    //////////////////////////////////////////////////////////////*/

    function testCalculatePrizesThreeWay() public {
        uint256 prizePool = 100 * 10**6; // 100 USDC

        uint256[] memory distribution = new uint256[](3);
        distribution[0] = 60; // 60%
        distribution[1] = 30; // 30%
        distribution[2] = 10; // 10%

        uint256[] memory prizes = PrizeDistributor.calculatePrizes(prizePool, distribution);

        assertEq(prizes.length, 3);
        assertEq(prizes[0], 60 * 10**6); // 60 USDC
        assertEq(prizes[1], 30 * 10**6); // 30 USDC
        assertEq(prizes[2], 10 * 10**6); // 10 USDC
    }

    function testCalculatePrizesTwoWay() public {
        uint256 prizePool = 50 * 10**6; // 50 USDC

        uint256[] memory distribution = new uint256[](2);
        distribution[0] = 70; // 70%
        distribution[1] = 30; // 30%

        uint256[] memory prizes = PrizeDistributor.calculatePrizes(prizePool, distribution);

        assertEq(prizes.length, 2);
        assertEq(prizes[0], 35 * 10**6); // 35 USDC
        assertEq(prizes[1], 15 * 10**6); // 15 USDC
    }

    function testCalculatePrizesWinnerTakesAll() public {
        uint256 prizePool = 100 * 10**6;

        uint256[] memory distribution = new uint256[](1);
        distribution[0] = 100;

        uint256[] memory prizes = PrizeDistributor.calculatePrizes(prizePool, distribution);

        assertEq(prizes.length, 1);
        assertEq(prizes[0], 100 * 10**6);
    }

    function testCalculatePrizesLargePrizePool() public {
        uint256 prizePool = 1000000 * 10**6; // 1 million USDC

        uint256[] memory distribution = new uint256[](3);
        distribution[0] = 50;
        distribution[1] = 30;
        distribution[2] = 20;

        uint256[] memory prizes = PrizeDistributor.calculatePrizes(prizePool, distribution);

        assertEq(prizes[0], 500000 * 10**6);
        assertEq(prizes[1], 300000 * 10**6);
        assertEq(prizes[2], 200000 * 10**6);
    }

    function testCannotCalculatePrizesWithZeroPool() public {
        uint256[] memory distribution = new uint256[](2);
        distribution[0] = 60;
        distribution[1] = 40;

        vm.expectRevert(PrizeDistributor.InvalidPrizePool.selector);
        wrapper.calculatePrizes(0, distribution);
    }

    function testCannotCalculatePrizesWithEmptyDistribution() public {
        uint256 prizePool = 100 * 10**6;
        uint256[] memory distribution = new uint256[](0);

        vm.expectRevert(PrizeDistributor.InvalidDistribution.selector);
        wrapper.calculatePrizes(prizePool, distribution);
    }

    /*//////////////////////////////////////////////////////////////
                    VALIDATE DISTRIBUTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testValidateDistributionValid() public {
        uint256[] memory distribution = new uint256[](3);
        distribution[0] = 60;
        distribution[1] = 30;
        distribution[2] = 10;

        bool valid = PrizeDistributor.validateDistribution(distribution);
        assertTrue(valid);
    }

    function testValidateDistributionTwoWay() public {
        uint256[] memory distribution = new uint256[](2);
        distribution[0] = 70;
        distribution[1] = 30;

        bool valid = PrizeDistributor.validateDistribution(distribution);
        assertTrue(valid);
    }

    function testValidateDistributionWinnerTakesAll() public {
        uint256[] memory distribution = new uint256[](1);
        distribution[0] = 100;

        bool valid = PrizeDistributor.validateDistribution(distribution);
        assertTrue(valid);
    }

    function testValidateDistributionInvalidSum() public {
        uint256[] memory distribution = new uint256[](3);
        distribution[0] = 60;
        distribution[1] = 30;
        distribution[2] = 5; // Only sums to 95

        bool valid = PrizeDistributor.validateDistribution(distribution);
        assertFalse(valid);
    }

    function testValidateDistributionExceedsHundred() public {
        uint256[] memory distribution = new uint256[](2);
        distribution[0] = 60;
        distribution[1] = 50; // Sums to 110

        bool valid = PrizeDistributor.validateDistribution(distribution);
        assertFalse(valid);
    }

    function testValidateDistributionWithZero() public {
        uint256[] memory distribution = new uint256[](3);
        distribution[0] = 60;
        distribution[1] = 0; // Zero not allowed
        distribution[2] = 40;

        bool valid = PrizeDistributor.validateDistribution(distribution);
        assertFalse(valid);
    }

    function testValidateDistributionEmpty() public {
        uint256[] memory distribution = new uint256[](0);

        bool valid = PrizeDistributor.validateDistribution(distribution);
        assertFalse(valid);
    }

    /*//////////////////////////////////////////////////////////////
                   CALCULATE SINGLE PRIZE TESTS
    //////////////////////////////////////////////////////////////*/

    function testCalculateSinglePrize() public {
        uint256 prizePool = 100 * 10**6;
        uint256 percentage = 60;

        uint256 prize = PrizeDistributor.calculateSinglePrize(prizePool, percentage);

        assertEq(prize, 60 * 10**6);
    }

    function testCalculateSinglePrizeFullAmount() public {
        uint256 prizePool = 100 * 10**6;
        uint256 percentage = 100;

        uint256 prize = PrizeDistributor.calculateSinglePrize(prizePool, percentage);

        assertEq(prize, 100 * 10**6);
    }

    function testCalculateSinglePrizeSmallPercentage() public {
        uint256 prizePool = 100 * 10**6;
        uint256 percentage = 1;

        uint256 prize = PrizeDistributor.calculateSinglePrize(prizePool, percentage);

        assertEq(prize, 1 * 10**6);
    }

    function testCannotCalculateSinglePrizeZeroPool() public {
        vm.expectRevert(PrizeDistributor.InvalidPrizePool.selector);
        wrapper.calculateSinglePrize(0, 50);
    }

    function testCannotCalculateSinglePrizeZeroPercentage() public {
        vm.expectRevert(PrizeDistributor.InvalidDistribution.selector);
        wrapper.calculateSinglePrize(100 * 10**6, 0);
    }

    function testCannotCalculateSinglePrizeOverHundred() public {
        vm.expectRevert(PrizeDistributor.InvalidDistribution.selector);
        wrapper.calculateSinglePrize(100 * 10**6, 101);
    }

    /*//////////////////////////////////////////////////////////////
                 VALIDATE PRIZE DISTRIBUTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testValidatePrizeDistributionValid() public {
        address[] memory winners = new address[](3);
        winners[0] = address(0x1);
        winners[1] = address(0x2);
        winners[2] = address(0x3);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 60 * 10**6;
        amounts[1] = 30 * 10**6;
        amounts[2] = 10 * 10**6;

        bool valid = PrizeDistributor.validatePrizeDistribution(winners, amounts);
        assertTrue(valid);
    }

    function testCannotValidatePrizeDistributionEmptyWinners() public {
        address[] memory winners = new address[](0);
        uint256[] memory amounts = new uint256[](0);

        vm.expectRevert(PrizeDistributor.EmptyWinnersList.selector);
        wrapper.validatePrizeDistribution(winners, amounts);
    }

    function testCannotValidatePrizeDistributionMismatchedArrays() public {
        address[] memory winners = new address[](3);
        winners[0] = address(0x1);
        winners[1] = address(0x2);
        winners[2] = address(0x3);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 60 * 10**6;
        amounts[1] = 40 * 10**6;

        bool valid = PrizeDistributor.validatePrizeDistribution(winners, amounts);
        assertFalse(valid);
    }

    function testCannotValidatePrizeDistributionZeroAddress() public {
        address[] memory winners = new address[](2);
        winners[0] = address(0x1);
        winners[1] = address(0); // Zero address

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 60 * 10**6;
        amounts[1] = 40 * 10**6;

        bool valid = PrizeDistributor.validatePrizeDistribution(winners, amounts);
        assertFalse(valid);
    }

    function testCannotValidatePrizeDistributionZeroAmount() public {
        address[] memory winners = new address[](2);
        winners[0] = address(0x1);
        winners[1] = address(0x2);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 60 * 10**6;
        amounts[1] = 0; // Zero amount

        bool valid = PrizeDistributor.validatePrizeDistribution(winners, amounts);
        assertFalse(valid);
    }

    /*//////////////////////////////////////////////////////////////
                     GET WINNER COUNT TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetWinnerCountLessParticipants() public {
        uint256 winnerCount = PrizeDistributor.getWinnerCount(3, 2);
        assertEq(winnerCount, 2); // Only 2 participants, so only 2 winners
    }

    function testGetWinnerCountEqualParticipants() public {
        uint256 winnerCount = PrizeDistributor.getWinnerCount(3, 3);
        assertEq(winnerCount, 3);
    }

    function testGetWinnerCountMoreParticipants() public {
        uint256 winnerCount = PrizeDistributor.getWinnerCount(3, 10);
        assertEq(winnerCount, 3); // 3 prize tiers, so 3 winners
    }

    function testGetWinnerCountSingle() public {
        uint256 winnerCount = PrizeDistributor.getWinnerCount(1, 100);
        assertEq(winnerCount, 1); // Winner takes all
    }

    /*//////////////////////////////////////////////////////////////
                         FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzCalculatePrizes(uint256 prizePool, uint8 pct1) public {
        vm.assume(prizePool > 0 && prizePool < type(uint128).max);
        vm.assume(pct1 > 0 && pct1 < 100);

        uint256 pct2 = 100 - uint256(pct1);

        uint256[] memory distribution = new uint256[](2);
        distribution[0] = pct1;
        distribution[1] = pct2;

        uint256[] memory prizes = PrizeDistributor.calculatePrizes(prizePool, distribution);

        assertEq(prizes.length, 2);
        assertTrue(prizes[0] + prizes[1] <= prizePool);
    }

    function testFuzzValidateDistribution(uint8 pct1, uint8 pct2, uint8 pct3) public {
        uint256[] memory distribution = new uint256[](3);
        distribution[0] = pct1;
        distribution[1] = pct2;
        distribution[2] = pct3;

        bool valid = PrizeDistributor.validateDistribution(distribution);

        if (pct1 == 0 || pct2 == 0 || pct3 == 0) {
            assertFalse(valid);
        } else if (uint256(pct1) + uint256(pct2) + uint256(pct3) != 100) {
            assertFalse(valid);
        } else {
            assertTrue(valid);
        }
    }
}
