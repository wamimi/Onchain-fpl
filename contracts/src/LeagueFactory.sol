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

    // Events
    event LeagueCreated(
        address indexed leagueAddress,
        address indexed creator,
        string name,
        uint256 entryFee,
        uint256 duration
    );
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);

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

        emit LeagueCreated(leagueAddress, msg.sender, name, entryFee, duration);

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
        emit OracleUpdated(oldOracle, newOracle);
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
}
