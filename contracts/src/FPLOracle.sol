// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

interface ILeague {
    function updateScores(address[] calldata participants, uint256[] calldata scores) external;
}

/**
 * @title FPLOracle
 * @notice Chainlink Functions oracle for fetching Fantasy Premier League scores
 * @dev Production-ready oracle with proper request tracking and ABI-encoded responses
 */
contract FPLOracle is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // ============================================
    // STATE VARIABLES
    // ============================================

    /// @notice Chainlink Functions subscription ID
    uint64 public subscriptionId;

    /// @notice Chainlink Functions DON ID for Base Sepolia
    bytes32 public donId;

    /// @notice Gas limit for callback function
    uint32 public gasLimit;

    /// @notice JavaScript source code for fetching FPL data
    string public source;

    /// @notice Track pending requests to prevent duplicates
    mapping(bytes32 => address) public pendingRequests;

    /// @notice Track last update timestamp per league
    mapping(address => uint256) public lastUpdateTime;

    /// @notice Minimum time between updates (prevents spam)
    uint256 public constant MIN_UPDATE_INTERVAL = 1 hours;

    // ============================================
    // EVENTS
    // ============================================

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

    // ============================================
    // ERRORS
    // ============================================

    error UnexpectedRequestID(bytes32 requestId);
    error UpdateTooSoon(uint256 lastUpdate, uint256 minInterval);
    error EmptyResponse();
    error InvalidArrayLengths();

    // ============================================
    // CONSTRUCTOR
    // ============================================

    /**
     * @notice Initialize the FPL Oracle
     * @param router Chainlink Functions router address for Base Sepolia
     * @param _subscriptionId Chainlink Functions subscription ID
     * @param _donId Decentralized Oracle Network ID
     * @param _gasLimit Gas limit for fulfillRequest callback
     */
    constructor(
        address router,
        uint64 _subscriptionId,
        bytes32 _donId,
        uint32 _gasLimit
    ) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        subscriptionId = _subscriptionId;
        donId = _donId;
        gasLimit = _gasLimit;
    }

    // ============================================
    // EXTERNAL FUNCTIONS
    // ============================================

    /**
     * @notice Request FPL scores update for a league
     * @param leagueAddress Address of the league contract
     * @param gameweek FPL gameweek number
     * @return requestId Chainlink Functions request ID
     */
    function requestScoresUpdate(address leagueAddress, uint256 gameweek)
        external
        onlyOwner
        returns (bytes32 requestId)
    {
        // Check rate limiting
        if (block.timestamp < lastUpdateTime[leagueAddress] + MIN_UPDATE_INTERVAL) {
            revert UpdateTooSoon(lastUpdateTime[leagueAddress], MIN_UPDATE_INTERVAL);
        }

        // Validate source code is set
        require(bytes(source).length > 0, "Source not set");

        // Build Chainlink Functions request
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);

        // Set arguments: [leagueAddress, gameweek]
        string[] memory args = new string[](2);
        args[0] = _addressToString(leagueAddress);
        args[1] = _uint256ToString(gameweek);
        req.setArgs(args);

        // Send request to Chainlink DON
        requestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donId
        );

        // Track pending request
        pendingRequests[requestId] = leagueAddress;

        emit ScoresRequested(requestId, leagueAddress, block.timestamp);

        return requestId;
    }

    /**
     * @notice Callback function called by Chainlink DON
     * @param requestId Request ID
     * @param response ABI-encoded response: (address[] participants, uint256[] scores)
     * @param err Error bytes (empty if successful)
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        address leagueAddress = pendingRequests[requestId];

        // Validate request exists
        if (leagueAddress == address(0)) {
            revert UnexpectedRequestID(requestId);
        }

        // Clear pending request
        delete pendingRequests[requestId];

        // Handle errors
        if (err.length > 0) {
            emit RequestFailed(requestId, leagueAddress, err);
            return;
        }

        // Validate response
        if (response.length == 0) {
            revert EmptyResponse();
        }

        // Decode ABI-encoded response
        (address[] memory participants, uint256[] memory scores) = abi.decode(
            response,
            (address[], uint256[])
        );

        // Validate arrays
        if (participants.length != scores.length) {
            revert InvalidArrayLengths();
        }

        // Update league scores
        ILeague(leagueAddress).updateScores(participants, scores);

        // Update last update time
        lastUpdateTime[leagueAddress] = block.timestamp;

        emit ScoresUpdated(requestId, leagueAddress, participants.length, block.timestamp);
    }

    // ============================================
    // OWNER FUNCTIONS
    // ============================================

    /**
     * @notice Update JavaScript source code
     * @param newSource New JavaScript source code
     */
    function updateSource(string calldata newSource) external onlyOwner {
        source = newSource;
        emit SourceUpdated(newSource);
    }

    /**
     * @notice Update gas limit for callbacks
     * @param newGasLimit New gas limit
     */
    function updateGasLimit(uint32 newGasLimit) external onlyOwner {
        gasLimit = newGasLimit;
        emit GasLimitUpdated(newGasLimit);
    }

    /**
     * @notice Update subscription ID
     * @param newSubscriptionId New subscription ID
     */
    function updateSubscriptionId(uint64 newSubscriptionId) external onlyOwner {
        subscriptionId = newSubscriptionId;
    }

    /**
     * @notice Update DON ID
     * @param newDonId New DON ID
     */
    function updateDonId(bytes32 newDonId) external onlyOwner {
        donId = newDonId;
    }

    // ============================================
    // VIEW FUNCTIONS
    // ============================================

    /**
     * @notice Check if a league can be updated
     * @param leagueAddress League address
     * @return canUpdate True if update is allowed
     */
    function canUpdateLeague(address leagueAddress) external view returns (bool) {
        return block.timestamp >= lastUpdateTime[leagueAddress] + MIN_UPDATE_INTERVAL;
    }

    /**
     * @notice Get time until next allowed update
     * @param leagueAddress League address
     * @return timeRemaining Seconds until next update (0 if can update now)
     */
    function getTimeUntilNextUpdate(address leagueAddress) external view returns (uint256) {
        uint256 nextUpdateTime = lastUpdateTime[leagueAddress] + MIN_UPDATE_INTERVAL;
        if (block.timestamp >= nextUpdateTime) {
            return 0;
        }
        return nextUpdateTime - block.timestamp;
    }

    // ============================================
    // INTERNAL HELPER FUNCTIONS
    // ============================================

    /**
     * @notice Convert address to string (lowercase, no 0x prefix)
     * @param _addr Address to convert
     * @return String representation
     */
    function _addressToString(address _addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(40);

        for (uint256 i = 0; i < 20; i++) {
            str[i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(str);
    }

    /**
     * @notice Convert uint256 to string
     * @param _i Number to convert
     * @return String representation
     */
    function _uint256ToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(bstr);
    }
}
