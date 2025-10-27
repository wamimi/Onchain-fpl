// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LeagueFactory.sol";
import "../src/League.sol";
import "../src/MockUSDC.sol";

contract LeagueFactoryTest is Test {
    LeagueFactory public factory;
    MockUSDC public usdc;
    address public oracle;
    address public creator;
    address public user1;
    address public user2;

    uint256 public constant ENTRY_FEE = 10 * 10**6; // 10 USDC
    uint256 public constant DURATION = 30 days;

    function setUp() public {
        oracle = makeAddr("oracle");
        creator = makeAddr("creator");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy USDC mock
        usdc = new MockUSDC();

        // Deploy factory
        factory = new LeagueFactory(address(usdc), oracle);

        // Mint USDC to users
        usdc.mint(creator, 1000 * 10**6);
        usdc.mint(user1, 1000 * 10**6);
        usdc.mint(user2, 1000 * 10**6);
    }

    function testCreateLeague() public {
        uint256[] memory prizeDistribution = new uint256[](3);
        prizeDistribution[0] = 60;
        prizeDistribution[1] = 30;
        prizeDistribution[2] = 10;

        vm.prank(creator);
        address leagueAddress = factory.createLeague(
            "Test League",
            ENTRY_FEE,
            DURATION,
            prizeDistribution
        );

        assertTrue(leagueAddress != address(0));
        assertTrue(factory.isLeague(leagueAddress));
    }

    function testGetLeagues() public {
        uint256[] memory prizeDistribution = new uint256[](2);
        prizeDistribution[0] = 70;
        prizeDistribution[1] = 30;

        vm.prank(creator);
        factory.createLeague("League 1", ENTRY_FEE, DURATION, prizeDistribution);

        address[] memory leagues = factory.getLeagues();
        assertEq(leagues.length, 1);
    }

    function testGetLeaguesByCreator() public {
        uint256[] memory prizeDistribution = new uint256[](2);
        prizeDistribution[0] = 70;
        prizeDistribution[1] = 30;

        vm.prank(creator);
        factory.createLeague("League 1", ENTRY_FEE, DURATION, prizeDistribution);

        vm.prank(creator);
        factory.createLeague("League 2", ENTRY_FEE, DURATION, prizeDistribution);

        address[] memory creatorLeagues = factory.getLeaguesByCreator(creator);
        assertEq(creatorLeagues.length, 2);
    }

    function testCannotCreateLeagueWithInvalidPrizeDistribution() public {
        uint256[] memory prizeDistribution = new uint256[](2);
        prizeDistribution[0] = 60;
        prizeDistribution[1] = 30; // Only sums to 90

        vm.prank(creator);
        vm.expectRevert(LeagueFactory.InvalidPrizeDistribution.selector);
        factory.createLeague("Test League", ENTRY_FEE, DURATION, prizeDistribution);
    }

    function testCannotCreateLeagueWithZeroEntryFee() public {
        uint256[] memory prizeDistribution = new uint256[](2);
        prizeDistribution[0] = 70;
        prizeDistribution[1] = 30;

        vm.prank(creator);
        vm.expectRevert(LeagueFactory.InvalidEntryFee.selector);
        factory.createLeague("Test League", 0, DURATION, prizeDistribution);
    }
}
