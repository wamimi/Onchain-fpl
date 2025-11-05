// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {FPLOracle} from "../src/FPLOracle.sol";

// Testable oracle that exposes fulfillRequest for testing
contract TestableFPLOracle is FPLOracle {
    constructor(
        address router,
        uint64 _subscriptionId,
        bytes32 _donId,
        uint32 _gasLimit
    ) FPLOracle(router, _subscriptionId, _donId, _gasLimit) {}

    // Expose fulfillRequest for testing
    function exposedFulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) external {
        fulfillRequest(requestId, response, err);
    }
}

contract MockLeague {
    address[] public lastParticipants;
    uint256[] public lastScores;
    bool public updateScoresCalled;

    function updateScores(address[] calldata participants, uint256[] calldata scores) external {
        updateScoresCalled = true;
        delete lastParticipants;
        delete lastScores;

        for (uint i = 0; i < participants.length; i++) {
            lastParticipants.push(participants[i]);
            lastScores.push(scores[i]);
        }
    }

    function getLastParticipants() external view returns (address[] memory) {
        return lastParticipants;
    }

    function getLastScores() external view returns (uint256[] memory) {
        return lastScores;
    }

    function reset() external {
        updateScoresCalled = false;
        delete lastParticipants;
        delete lastScores;
    }
}

contract MockFunctionsRouter {
    // Mock router that doesn't actually send requests
    function sendRequest(
        uint64,
        bytes memory,
        uint16,
        uint32,
        bytes32
    ) external pure returns (bytes32) {
        return bytes32(uint256(1)); // Return mock request ID
    }
}

contract FPLOracleTest is Test {
    TestableFPLOracle public oracle;
    MockLeague public mockLeague;
    MockFunctionsRouter public mockRouter;

    address public owner;
    address public nonOwner;

    // Base Sepolia config
    address constant ROUTER = address(0xf9B8fc078197181C841c296C876945aaa425B278);
    uint64 constant SUBSCRIPTION_ID = 1;
    bytes32 constant DON_ID = 0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000;
    uint32 constant GAS_LIMIT = 300000;

    string constant MOCK_SOURCE = "console.log('test');";

    event ScoresRequested(
        bytes32 indexed requestId,
        address indexed leagueAddress,
        uint256 timestamp
    );

    event ScoresUpdated(
        bytes32 indexed requestId,
        address indexed leagueAddress,
        uint256 participantCount,
        uint256 timestamp
    );

    event RequestFailed(
        bytes32 indexed requestId,
        address indexed leagueAddress,
        bytes error
    );

    event SourceUpdated(string newSource);
    event GasLimitUpdated(uint32 newGasLimit);

    function setUp() public {
        owner = address(this);
        nonOwner = makeAddr("nonOwner");

        // Deploy mock contracts
        mockRouter = new MockFunctionsRouter();
        mockLeague = new MockLeague();

        // Deploy testable oracle with mock router
        oracle = new TestableFPLOracle(
            address(mockRouter),
            SUBSCRIPTION_ID,
            DON_ID,
            GAS_LIMIT
        );

        // Set source code
        oracle.updateSource(MOCK_SOURCE);
    }

    // ============================================
    // CONSTRUCTOR TESTS
    // ============================================

    function test_Constructor() public {
        assertEq(oracle.subscriptionId(), SUBSCRIPTION_ID);
        assertEq(oracle.donId(), DON_ID);
        assertEq(oracle.gasLimit(), GAS_LIMIT);
    }

    function test_ConstructorSetsOwner() public {
        assertEq(oracle.owner(), owner);
    }

    // ============================================
    // REQUEST SCORES UPDATE TESTS
    // ============================================

    function test_RequestScoresUpdate() public {
        uint256 gameweek = 1;

        vm.expectEmit(false, true, false, true);
        emit ScoresRequested(bytes32(0), address(mockLeague), block.timestamp);

        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), gameweek);

        assertNotEq(requestId, bytes32(0));
        assertEq(oracle.pendingRequests(requestId), address(mockLeague));
    }

    function test_RequestScoresUpdateRevertsIfNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Only callable by owner");
        oracle.requestScoresUpdate(address(mockLeague), 1);
    }

    function test_RequestScoresUpdateRevertsIfSourceNotSet() public {
        // Deploy new oracle without source
        FPLOracle newOracle = new FPLOracle(
            address(mockRouter),
            SUBSCRIPTION_ID,
            DON_ID,
            GAS_LIMIT
        );

        vm.expectRevert("Source not set");
        newOracle.requestScoresUpdate(address(mockLeague), 1);
    }

    function test_RequestScoresUpdateRevertsIfUpdateTooSoon() public {
        // First request and fulfill it to set lastUpdateTime
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 1);

        // Simulate fulfillment
        address[] memory participants = new address[](1);
        uint256[] memory scores = new uint256[](1);
        participants[0] = address(0x123);
        scores[0] = 75;
        bytes memory response = abi.encode(participants, scores);

        oracle.exposedFulfillRequest(requestId, response, bytes(""));

        // Try to request again immediately (should fail)
        vm.expectRevert(
            abi.encodeWithSelector(
                FPLOracle.UpdateTooSoon.selector,
                block.timestamp,
                1 hours
            )
        );
        oracle.requestScoresUpdate(address(mockLeague), 1);
    }

    function test_RequestScoresUpdateAllowedAfterInterval() public {
        // First request
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 1);

        // Simulate fulfillment to update lastUpdateTime
        address[] memory participants = new address[](1);
        uint256[] memory scores = new uint256[](1);
        participants[0] = address(0x123);
        scores[0] = 75;
        bytes memory response = abi.encode(participants, scores);

        oracle.exposedFulfillRequest(requestId, response, bytes(""));

        // Fast forward past rate limit
        vm.warp(block.timestamp + 1 hours + 1);

        // Should allow new request
        bytes32 newRequestId = oracle.requestScoresUpdate(address(mockLeague), 2);
        assertNotEq(newRequestId, bytes32(0));
    }

    // ============================================
    // UPDATE SOURCE TESTS
    // ============================================

    function test_UpdateSource() public {
        string memory newSource = "console.log('new source');";

        vm.expectEmit(true, true, true, true);
        emit SourceUpdated(newSource);

        oracle.updateSource(newSource);
        assertEq(oracle.source(), newSource);
    }

    function test_UpdateSourceRevertsIfNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Only callable by owner");
        oracle.updateSource("new source");
    }

    // ============================================
    // UPDATE GAS LIMIT TESTS
    // ============================================

    function test_UpdateGasLimit() public {
        uint32 newGasLimit = 400000;

        vm.expectEmit(true, true, true, true);
        emit GasLimitUpdated(newGasLimit);

        oracle.updateGasLimit(newGasLimit);
        assertEq(oracle.gasLimit(), newGasLimit);
    }

    function test_UpdateGasLimitRevertsIfNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Only callable by owner");
        oracle.updateGasLimit(400000);
    }

    // ============================================
    // UPDATE SUBSCRIPTION ID TESTS
    // ============================================

    function test_UpdateSubscriptionId() public {
        uint64 newSubId = 999;
        oracle.updateSubscriptionId(newSubId);
        assertEq(oracle.subscriptionId(), newSubId);
    }

    function test_UpdateSubscriptionIdRevertsIfNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Only callable by owner");
        oracle.updateSubscriptionId(999);
    }

    // ============================================
    // UPDATE DON ID TESTS
    // ============================================

    function test_UpdateDonId() public {
        bytes32 newDonId = bytes32(uint256(123));
        oracle.updateDonId(newDonId);
        assertEq(oracle.donId(), newDonId);
    }

    function test_UpdateDonIdRevertsIfNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert("Only callable by owner");
        oracle.updateDonId(bytes32(uint256(123)));
    }

    // ============================================
    // VIEW FUNCTION TESTS
    // ============================================

    function test_CanUpdateLeague_ReturnsTrueInitially() public {
        assertTrue(oracle.canUpdateLeague(address(mockLeague)));
    }

    function test_CanUpdateLeague_ReturnsFalseAfterRecentUpdate() public {
        // Make a request and fulfill it to set lastUpdateTime
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 1);

        address[] memory participants = new address[](1);
        uint256[] memory scores = new uint256[](1);
        participants[0] = address(0x123);
        scores[0] = 75;
        bytes memory response = abi.encode(participants, scores);

        oracle.exposedFulfillRequest(requestId, response, bytes(""));

        assertFalse(oracle.canUpdateLeague(address(mockLeague)));
    }

    function test_CanUpdateLeague_ReturnsTrueAfterInterval() public {
        // Make a request and fulfill it
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 1);

        address[] memory participants = new address[](1);
        uint256[] memory scores = new uint256[](1);
        participants[0] = address(0x123);
        scores[0] = 75;
        bytes memory response = abi.encode(participants, scores);

        oracle.exposedFulfillRequest(requestId, response, bytes(""));

        // Fast forward past interval
        vm.warp(block.timestamp + 1 hours + 1);

        assertTrue(oracle.canUpdateLeague(address(mockLeague)));
    }

    function test_GetTimeUntilNextUpdate_ReturnsZeroInitially() public {
        assertEq(oracle.getTimeUntilNextUpdate(address(mockLeague)), 0);
    }

    function test_GetTimeUntilNextUpdate_ReturnsCorrectTime() public {
        // Make a request and fulfill it
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 1);

        address[] memory participants = new address[](1);
        uint256[] memory scores = new uint256[](1);
        participants[0] = address(0x123);
        scores[0] = 75;
        bytes memory response = abi.encode(participants, scores);

        uint256 updateTime = block.timestamp;
        oracle.exposedFulfillRequest(requestId, response, bytes(""));

        assertEq(oracle.getTimeUntilNextUpdate(address(mockLeague)), 1 hours);

        // Fast forward 30 minutes
        vm.warp(updateTime + 30 minutes);
        assertEq(oracle.getTimeUntilNextUpdate(address(mockLeague)), 30 minutes);
    }

    function test_GetTimeUntilNextUpdate_ReturnsZeroAfterInterval() public {
        // Make a request and fulfill it
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 1);

        address[] memory participants = new address[](1);
        uint256[] memory scores = new uint256[](1);
        participants[0] = address(0x123);
        scores[0] = 75;
        bytes memory response = abi.encode(participants, scores);

        uint256 updateTime = block.timestamp;
        oracle.exposedFulfillRequest(requestId, response, bytes(""));

        // Fast forward past interval
        vm.warp(updateTime + 2 hours);
        assertEq(oracle.getTimeUntilNextUpdate(address(mockLeague)), 0);
    }

    // ============================================
    // HELPER FUNCTION TESTS (via internal testing)
    // ============================================

    function test_AddressToString() public {
        // Test via requestScoresUpdate which uses _addressToString
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 1);
        assertNotEq(requestId, bytes32(0));
        // If it didn't revert, address conversion worked
    }

    function test_Uint256ToString() public {
        // Test via requestScoresUpdate which uses _uint256ToString
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 12345);
        assertNotEq(requestId, bytes32(0));
        // If it didn't revert, uint256 conversion worked
    }

    // ============================================
    // EDGE CASES
    // ============================================

    function test_RequestScoresUpdate_WithGameweekZero() public {
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 0);
        assertNotEq(requestId, bytes32(0));
    }

    function test_RequestScoresUpdate_WithHighGameweek() public {
        bytes32 requestId = oracle.requestScoresUpdate(address(mockLeague), 38);
        assertNotEq(requestId, bytes32(0));
    }

    function test_RequestScoresUpdate_WithDifferentLeagues() public {
        address league1 = address(mockLeague);
        address league2 = makeAddr("league2");

        // Should be able to request for different leagues without rate limit
        bytes32 requestId1 = oracle.requestScoresUpdate(league1, 1);
        bytes32 requestId2 = oracle.requestScoresUpdate(league2, 1);

        assertNotEq(requestId1, bytes32(0));
        assertNotEq(requestId2, bytes32(0));
        // Note: Mock router returns same ID, so second request overwrites first
        // In production, Chainlink returns unique IDs for each request
        // Just verify both requests completed successfully
        assertEq(oracle.pendingRequests(requestId2), league2);
    }
}
