// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./League.sol";
import "./PrizeDistributor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title LeagueFactory
 * @notice Factory contract for creating and managing FPL betting leagues
 * @dev Implements Ownable and Pausable for admin control
 */
contract LeagueFactory is Ownable, Pausable {
    // State variables
    address public immutable usdc;
    address public oracle;

    address[] public allLeagues;
    mapping(address => address[]) public leaguesByCreator;
    mapping(address => bool) public isLeague;

    // Events - Enhanced for frontend indexing
    event LeagueCreated(
        address indexed leagueAddress,
        address indexed creator,
        string name,
        uint256 entryFee,
        uint256 duration,
        uint256 timestamp
    );
    event OracleUpdated(address indexed oldOracle, address indexed newOracle, uint256 timestamp);

    // Errors
    error ZeroAddress();
    error InvalidDuration();
    error InvalidEntryFee();
    error InvalidPrizeDistribution();

    /**
     * @notice Initialize factory with USDC address
     * @param _usdc USDC token address on Base
     * @param _oracle Initial oracle address
     */
    constructor(address _usdc, address _oracle) Ownable(msg.sender) {
        if (_usdc == address(0) || _oracle == address(0)) revert ZeroAddress();
        usdc = _usdc;
        oracle = _oracle;
    }

    /**
     * @notice Create a new league
     * @param name League name
     * @param entryFee Entry fee in USDC (with 6 decimals)
     * @param duration League duration in seconds
     * @param prizeDistribution Array of prize percentages (must sum to 100)
     * @return leagueAddress Address of newly created league
     */
    function createLeague(
        string calldata name,
        uint256 entryFee,
        uint256 duration,
        uint256[] calldata prizeDistribution
    ) external whenNotPaused returns (address) {
        if (entryFee == 0) revert InvalidEntryFee();
        if (duration == 0) revert InvalidDuration();
        if (!_validatePrizeDistribution(prizeDistribution)) revert InvalidPrizeDistribution();

        // Deploy new League contract
        League newLeague = new League(
            usdc,
            msg.sender,
            name,
            entryFee,
            duration,
            prizeDistribution,
            oracle
        );

        address leagueAddress = address(newLeague);

        // Track league
        allLeagues.push(leagueAddress);
        leaguesByCreator[msg.sender].push(leagueAddress);
        isLeague[leagueAddress] = true;

        emit LeagueCreated(leagueAddress, msg.sender, name, entryFee, duration, block.timestamp);

        return leagueAddress;
    }

    /**
     * @notice Get all created leagues
     * @return Array of league addresses
     */
    function getLeagues() external view returns (address[] memory) {
        return allLeagues;
    }

    /**
     * @notice Get leagues created by a specific address
     * @param creator Creator address
     * @return Array of league addresses
     */
    function getLeaguesByCreator(address creator) external view returns (address[] memory) {
        return leaguesByCreator[creator];
    }

    /**
     * @notice Get total number of leagues
     * @return Total league count
     */
    function getTotalLeagues() external view returns (uint256) {
        return allLeagues.length;
    }

    /**
     * @notice Update oracle address
     * @param newOracle New oracle address
     */
    function setOracle(address newOracle) external onlyOwner {
        if (newOracle == address(0)) revert ZeroAddress();
        address oldOracle = oracle;
        oracle = newOracle;
        emit OracleUpdated(oldOracle, newOracle, block.timestamp);
    }

    /**
     * @notice Pause factory (prevents new league creation)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause factory
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Validate prize distribution sums to 100
     * @param distribution Array of percentages
     * @return true if valid
     */
    function _validatePrizeDistribution(uint256[] calldata distribution) private pure returns (bool) {
        // Convert calldata to memory for library call
        uint256[] memory dist = new uint256[](distribution.length);
        for (uint256 i = 0; i < distribution.length; i++) {
            dist[i] = distribution[i];
        }
        return PrizeDistributor.validateDistribution(dist);
    }

    /*//////////////////////////////////////////////////////////////
                    FRONTEND VIEW FUNCTIONS (PAGINATED)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get paginated list of leagues
     * @param offset Starting index
     * @param limit Number of leagues to return
     * @return Array of league addresses
     */
    function getLeaguesPaginated(uint256 offset, uint256 limit) external view returns (address[] memory) {
        if (offset >= allLeagues.length) {
            return new address[](0);
        }

        uint256 end = offset + limit;
        if (end > allLeagues.length) {
            end = allLeagues.length;
        }

        uint256 resultLength = end - offset;
        address[] memory result = new address[](resultLength);

        for (uint256 i = 0; i < resultLength; i++) {
            result[i] = allLeagues[offset + i];
        }

        return result;
    }

    /**
     * @notice Get active (joinable) leagues with pagination
     * @param offset Starting index
     * @param limit Max number to return
     * @return Array of active league addresses
     */
    function getActiveLeaguesPaginated(uint256 offset, uint256 limit)
        external
        view
        returns (address[] memory)
    {
        // First pass: count active leagues and find offset position
        uint256 activeCount = 0;
        uint256 offsetPosition = 0;
        bool foundOffset = false;

        for (uint256 i = 0; i < allLeagues.length; i++) {
            League league = League(allLeagues[i]);
            if (league.isJoinable()) {
                if (!foundOffset) {
                    if (activeCount == offset) {
                        offsetPosition = i;
                        foundOffset = true;
                    }
                    activeCount++;
                } else if (activeCount < offset + limit) {
                    activeCount++;
                } else {
                    break;
                }
            }
        }

        if (!foundOffset || activeCount <= offset) {
            return new address[](0);
        }

        // Second pass: collect leagues
        uint256 resultLength = activeCount - offset > limit ? limit : activeCount - offset;
        address[] memory result = new address[](resultLength);
        uint256 resultIndex = 0;
        uint256 currentActiveIndex = 0;

        for (uint256 i = offsetPosition; i < allLeagues.length && resultIndex < resultLength; i++) {
            League league = League(allLeagues[i]);
            if (league.isJoinable()) {
                if (currentActiveIndex >= offset) {
                    result[resultIndex] = allLeagues[i];
                    resultIndex++;
                }
                currentActiveIndex++;
            }
        }

        return result;
    }

    /**
     * @notice Get quick stats about all leagues
     * @return total Total number of leagues
     * @return active Number of active (joinable) leagues
     */
    function getLeagueStats() external view returns (uint256 total, uint256 active) {
        total = allLeagues.length;
        active = 0;

        for (uint256 i = 0; i < allLeagues.length; i++) {
            League league = League(allLeagues[i]);
            if (league.isJoinable()) {
                active++;
            }
        }
    }
}
