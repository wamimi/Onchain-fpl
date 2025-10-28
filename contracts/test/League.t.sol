// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/League.sol";
import "../src/MockUSDC.sol";

contract LeagueTest is Test {
    League public league;
    MockUSDC public usdc;

    address public creator;
    address public oracle;
    address public user1;
    address public user2;
    address public user3;

    uint256 public constant ENTRY_FEE = 10 * 10**6; // 10 USDC
    uint256 public constant DURATION = 30 days;

    event ParticipantJoined(address indexed participant, uint256 entryFee, uint256 participantCount, uint256 timestamp);
    event ScoresUpdated(address[] participants, uint256[] scores, uint256 timestamp);
    event LeagueFinalized(address[] winners, uint256[] prizes, uint256 timestamp);
    event PrizeClaimed(address indexed winner, uint256 amount, uint256 totalClaimed, uint256 timestamp);

    function setUp() public {
        creator = makeAddr("creator");
        oracle = makeAddr("oracle");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Deploy USDC
        usdc = new MockUSDC();

        // Setup prize distribution: 60% / 30% / 10%
        uint256[] memory prizeDistribution = new uint256[](3);
        prizeDistribution[0] = 60;
        prizeDistribution[1] = 30;
        prizeDistribution[2] = 10;

        // Deploy League
        vm.prank(creator);
        league = new League(
            address(usdc),
            creator,
            "Test League",
            ENTRY_FEE,
            DURATION,
            prizeDistribution,
            oracle
        );

        // Mint USDC to users
        usdc.mint(user1, 1000 * 10**6);
        usdc.mint(user2, 1000 * 10**6);
        usdc.mint(user3, 1000 * 10**6);
    }

    /*//////////////////////////////////////////////////////////////
                            JOIN LEAGUE TESTS
    //////////////////////////////////////////////////////////////*/

    function testJoinLeague() public {
        vm.startPrank(user1);
        usdc.approve(address(league), ENTRY_FEE);

        vm.expectEmit(true, false, false, true);
        emit ParticipantJoined(user1, ENTRY_FEE, 1, block.timestamp);

        league.joinLeague();
        vm.stopPrank();

        assertTrue(league.participants(user1));
        assertEq(league.prizePool(), ENTRY_FEE);
        assertEq(usdc.balanceOf(address(league)), ENTRY_FEE);
    }

    function testMultipleUsersJoinLeague() public {
        // User 1 joins
        vm.startPrank(user1);
        usdc.approve(address(league), ENTRY_FEE);
        league.joinLeague();
        vm.stopPrank();

        // User 2 joins
        vm.startPrank(user2);
        usdc.approve(address(league), ENTRY_FEE);
        league.joinLeague();
        vm.stopPrank();

        // User 3 joins
        vm.startPrank(user3);
        usdc.approve(address(league), ENTRY_FEE);
        league.joinLeague();
        vm.stopPrank();

        assertTrue(league.participants(user1));
        assertTrue(league.participants(user2));
        assertTrue(league.participants(user3));
        assertEq(league.prizePool(), ENTRY_FEE * 3);
    }

    function testCannotJoinTwice() public {
        vm.startPrank(user1);
        usdc.approve(address(league), ENTRY_FEE * 2);
        league.joinLeague();

        vm.expectRevert(League.AlreadyJoined.selector);
        league.joinLeague();
        vm.stopPrank();
    }

    function testCannotJoinAfterLeagueEnds() public {
        // Warp time past league end
        vm.warp(block.timestamp + DURATION + 1);

        vm.startPrank(user1);
        usdc.approve(address(league), ENTRY_FEE);
        vm.expectRevert(League.LeagueEnded.selector);
        league.joinLeague();
        vm.stopPrank();
    }

    function testCannotJoinWithoutApproval() public {
        vm.startPrank(user1);
        vm.expectRevert();
        league.joinLeague();
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                         SCORE UPDATE TESTS
    //////////////////////////////////////////////////////////////*/

    function testOracleCanUpdateScores() public {
        // Users join league
        _joinLeague(user1);
        _joinLeague(user2);
        _joinLeague(user3);

        // Warp past league end
        vm.warp(block.timestamp + DURATION + 1);

        // Prepare score data
        address[] memory participants = new address[](3);
        participants[0] = user1;
        participants[1] = user2;
        participants[2] = user3;

        uint256[] memory scores = new uint256[](3);
        scores[0] = 100;
        scores[1] = 90;
        scores[2] = 80;

        // Oracle updates scores
        vm.prank(oracle);
        vm.expectEmit(false, false, false, true);
        emit ScoresUpdated(participants, scores, block.timestamp);

        league.updateScores(participants, scores);

        assertEq(league.fplScores(user1), 100);
        assertEq(league.fplScores(user2), 90);
        assertEq(league.fplScores(user3), 80);
        assertTrue(league.scoresUpdated());
    }

    function testCannotUpdateScoresBeforeLeagueEnds() public {
        _joinLeague(user1);

        address[] memory participants = new address[](1);
        participants[0] = user1;
        uint256[] memory scores = new uint256[](1);
        scores[0] = 100;

        vm.prank(oracle);
        vm.expectRevert(League.LeagueNotEnded.selector);
        league.updateScores(participants, scores);
    }

    function testNonOracleCannotUpdateScores() public {
        _joinLeague(user1);
        vm.warp(block.timestamp + DURATION + 1);

        address[] memory participants = new address[](1);
        participants[0] = user1;
        uint256[] memory scores = new uint256[](1);
        scores[0] = 100;

        vm.prank(user1);
        vm.expectRevert();
        league.updateScores(participants, scores);
    }

    function testCannotUpdateScoresWithMismatchedArrays() public {
        _joinLeague(user1);
        vm.warp(block.timestamp + DURATION + 1);

        address[] memory participants = new address[](2);
        participants[0] = user1;
        participants[1] = user2;

        uint256[] memory scores = new uint256[](1);
        scores[0] = 100;

        vm.prank(oracle);
        vm.expectRevert(League.InvalidScoresLength.selector);
        league.updateScores(participants, scores);
    }

    /*//////////////////////////////////////////////////////////////
                        FINALIZATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testFinalizeLeague() public {
        // Users join
        _joinLeague(user1);
        _joinLeague(user2);
        _joinLeague(user3);

        uint256 totalPrizePool = ENTRY_FEE * 3;

        // Warp and update scores
        vm.warp(block.timestamp + DURATION + 1);

        address[] memory participants = new address[](3);
        participants[0] = user1;
        participants[1] = user2;
        participants[2] = user3;

        uint256[] memory scores = new uint256[](3);
        scores[0] = 100; // Winner
        scores[1] = 90;  // Second
        scores[2] = 80;  // Third

        vm.prank(oracle);
        league.updateScores(participants, scores);

        // Finalize
        vm.prank(creator);
        league.finalizeLeague();

        assertTrue(league.finalized());

        // Check prize calculations: 60% / 30% / 10%
        uint256 firstPrize = (totalPrizePool * 60) / 100;
        uint256 secondPrize = (totalPrizePool * 30) / 100;
        uint256 thirdPrize = (totalPrizePool * 10) / 100;

        assertEq(league.claimableWinnings(user1), firstPrize);
        assertEq(league.claimableWinnings(user2), secondPrize);
        assertEq(league.claimableWinnings(user3), thirdPrize);
    }

    function testCannotFinalizeBeforeLeagueEnds() public {
        _joinLeague(user1);

        vm.prank(creator);
        vm.expectRevert(League.LeagueNotEnded.selector);
        league.finalizeLeague();
    }

    function testCannotFinalizeWithoutScores() public {
        _joinLeague(user1);
        vm.warp(block.timestamp + DURATION + 1);

        vm.prank(creator);
        vm.expectRevert("Scores not updated");
        league.finalizeLeague();
    }

    function testCannotFinalizeTwice() public {
        _joinLeague(user1);

        vm.warp(block.timestamp + DURATION + 1);

        address[] memory participants = new address[](1);
        participants[0] = user1;
        uint256[] memory scores = new uint256[](1);
        scores[0] = 100;

        vm.prank(oracle);
        league.updateScores(participants, scores);

        vm.prank(creator);
        league.finalizeLeague();

        vm.prank(creator);
        vm.expectRevert(League.AlreadyFinalized.selector);
        league.finalizeLeague();
    }

    function testNonCreatorCannotFinalize() public {
        _joinLeague(user1);

        vm.warp(block.timestamp + DURATION + 1);

        address[] memory participants = new address[](1);
        participants[0] = user1;
        uint256[] memory scores = new uint256[](1);
        scores[0] = 100;

        vm.prank(oracle);
        league.updateScores(participants, scores);

        vm.prank(user1);
        vm.expectRevert();
        league.finalizeLeague();
    }

    /*//////////////////////////////////////////////////////////////
                         PRIZE CLAIM TESTS
    //////////////////////////////////////////////////////////////*/

    function testClaimPrize() public {
        // Setup and finalize league
        _joinLeague(user1);
        _joinLeague(user2);

        vm.warp(block.timestamp + DURATION + 1);

        address[] memory participants = new address[](2);
        participants[0] = user1;
        participants[1] = user2;
        uint256[] memory scores = new uint256[](2);
        scores[0] = 100;
        scores[1] = 90;

        vm.prank(oracle);
        league.updateScores(participants, scores);

        vm.prank(creator);
        league.finalizeLeague();

        // User1 claims prize
        uint256 prize = league.claimableWinnings(user1);
        uint256 balanceBefore = usdc.balanceOf(user1);

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit PrizeClaimed(user1, prize, prize, block.timestamp);

        league.claimPrize();

        assertEq(usdc.balanceOf(user1), balanceBefore + prize);
        assertEq(league.claimableWinnings(user1), 0);
    }

    function testCannotClaimBeforeFinalization() public {
        _joinLeague(user1);

        vm.prank(user1);
        vm.expectRevert(League.NotFinalized.selector);
        league.claimPrize();
    }

    function testCannotClaimWithNoWinnings() public {
        _joinLeague(user1);

        vm.warp(block.timestamp + DURATION + 1);

        address[] memory participants = new address[](1);
        participants[0] = user1;
        uint256[] memory scores = new uint256[](1);
        scores[0] = 100;

        vm.prank(oracle);
        league.updateScores(participants, scores);

        vm.prank(creator);
        league.finalizeLeague();

        // User2 didn't join, has no winnings
        vm.prank(user2);
        vm.expectRevert(League.NoClaimableWinnings.selector);
        league.claimPrize();
    }

    function testCannotClaimTwice() public {
        _joinLeague(user1);

        vm.warp(block.timestamp + DURATION + 1);

        address[] memory participants = new address[](1);
        participants[0] = user1;
        uint256[] memory scores = new uint256[](1);
        scores[0] = 100;

        vm.prank(oracle);
        league.updateScores(participants, scores);

        vm.prank(creator);
        league.finalizeLeague();

        vm.startPrank(user1);
        league.claimPrize();

        vm.expectRevert(League.NoClaimableWinnings.selector);
        league.claimPrize();
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                          HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _joinLeague(address user) internal {
        vm.startPrank(user);
        usdc.approve(address(league), ENTRY_FEE);
        league.joinLeague();
        vm.stopPrank();
    }
}
