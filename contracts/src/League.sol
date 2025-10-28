// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./PrizeDistributor.sol";

/**
 * @title League
 * @notice Manages a single FPL betting league with USDC stakes and automated prize distribution
 * @dev Implements security patterns: ReentrancyGuard, AccessControl, Pausable
 */
contract League is ReentrancyGuard, AccessControl, Pausable {
    using SafeERC20 for IERC20;

    // Roles
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    // Enums
    enum LeagueStatus {
        NotStarted,
        Active,
        Ended,
        Finalized,
        Cancelled
    }

    // Structs for frontend
    struct LeagueInfo {
        string name;
        address creator;
        uint256 entryFee;
        uint256 prizePool;
        uint256 startTime;
        uint256 endTime;
        uint256 participantCount;
        bool finalized;
        bool scoresUpdated;
        LeagueStatus status;
    }

    struct ParticipantInfo {
        address participant;
        uint256 score;
        uint256 rank;
        uint256 claimableWinnings;
        bool hasClaimed;
    }

    // State variables
    IERC20 public immutable usdc;
    address public immutable creator;
    string public leagueName;
    uint256 public immutable entryFee;
    uint256 public prizePool;
    uint256 public immutable startTime;
    uint256 public immutable endTime;
    uint256[] public prizeDistribution; // Percentages (e.g., [60, 30, 10])

    address[] public participantList;
    mapping(address => bool) public participants;
    mapping(address => uint256) public fplScores;
    mapping(address => uint256) public claimableWinnings;
    mapping(address => bool) public hasClaimed;

    bool public finalized;
    bool public scoresUpdated;
    uint256 public totalClaimed;

    // Events - Enhanced for frontend indexing
    event ParticipantJoined(address indexed participant, uint256 entryFee, uint256 participantCount, uint256 timestamp);
    event ScoresUpdated(address[] participants, uint256[] scores, uint256 timestamp);
    event LeagueFinalized(address[] winners, uint256[] prizes, uint256 timestamp);
    event PrizeClaimed(address indexed winner, uint256 amount, uint256 totalClaimed, uint256 timestamp);
    event EmergencyWithdraw(address indexed participant, uint256 amount, uint256 timestamp);
    event LeagueStatusChanged(LeagueStatus indexed oldStatus, LeagueStatus indexed newStatus, uint256 timestamp);

    // Errors
    error InvalidPrizeDistribution();
    error AlreadyJoined();
    error LeagueNotStarted();
    error LeagueEnded();
    error LeagueNotEnded();
    error AlreadyFinalized();
    error NotFinalized();
    error NoClaimableWinnings();
    error InvalidScoresLength();
    error ZeroAddress();

    /**
     * @notice Creates a new league
     * @param _usdc USDC token address
     * @param _creator League creator address
     * @param _name League name
     * @param _entryFee Entry fee in USDC (with 6 decimals)
     * @param _duration League duration in seconds
     * @param _prizeDistribution Array of prize percentages (must sum to 100)
     * @param _oracle Oracle address for score updates
     */
    constructor(
        address _usdc,
        address _creator,
        string memory _name,
        uint256 _entryFee,
        uint256 _duration,
        uint256[] memory _prizeDistribution,
        address _oracle
    ) {
        if (_usdc == address(0) || _creator == address(0)) revert ZeroAddress();
        if (!_validatePrizeDistribution(_prizeDistribution)) revert InvalidPrizeDistribution();

        usdc = IERC20(_usdc);
        creator = _creator;
        leagueName = _name;
        entryFee = _entryFee;
        startTime = block.timestamp;
        endTime = block.timestamp + _duration;
        prizeDistribution = _prizeDistribution;

        _grantRole(DEFAULT_ADMIN_ROLE, _creator);
        _grantRole(CREATOR_ROLE, _creator);
        if (_oracle != address(0)) {
            _grantRole(ORACLE_ROLE, _oracle);
        }
    }

    /**
     * @notice Join the league by staking USDC
     * @dev Requires prior USDC approval
     */
    function joinLeague() external nonReentrant whenNotPaused {
        if (block.timestamp < startTime) revert LeagueNotStarted();
        if (block.timestamp >= endTime) revert LeagueEnded();
        if (participants[msg.sender]) revert AlreadyJoined();

        participants[msg.sender] = true;
        participantList.push(msg.sender);
        prizePool += entryFee;

        usdc.safeTransferFrom(msg.sender, address(this), entryFee);

        emit ParticipantJoined(msg.sender, entryFee, participantList.length, block.timestamp);
    }

    /**
     * @notice Update FPL scores for participants (oracle only)
     * @param _participants Array of participant addresses
     * @param _scores Array of corresponding FPL scores
     */
    function updateScores(address[] calldata _participants, uint256[] calldata _scores)
        external
        onlyRole(ORACLE_ROLE)
    {
        if (_participants.length != _scores.length) revert InvalidScoresLength();
        if (block.timestamp < endTime) revert LeagueNotEnded();

        for (uint256 i = 0; i < _participants.length; i++) {
            fplScores[_participants[i]] = _scores[i];
        }

        scoresUpdated = true;
        emit ScoresUpdated(_participants, _scores, block.timestamp);
    }

    /**
     * @notice Finalize league and calculate prize distribution
     * @dev Can only be called after scores are updated
     */
    function finalizeLeague() external onlyRole(CREATOR_ROLE) {
        if (block.timestamp < endTime) revert LeagueNotEnded();
        if (finalized) revert AlreadyFinalized();
        if (!scoresUpdated) revert("Scores not updated");

        finalized = true;

        // Sort participants by score (descending)
        address[] memory winners = _getRankedParticipants();

        // Calculate and assign prizes
        uint256 winnersCount = prizeDistribution.length;
        if (winnersCount > participantList.length) {
            winnersCount = participantList.length;
        }

        uint256[] memory prizes = new uint256[](winnersCount);
        for (uint256 i = 0; i < winnersCount; i++) {
            uint256 prizeAmount = (prizePool * prizeDistribution[i]) / 100;
            claimableWinnings[winners[i]] = prizeAmount;
            prizes[i] = prizeAmount;
        }

        emit LeagueFinalized(winners, prizes, block.timestamp);
    }

    /**
     * @notice Claim prize winnings
     */
    function claimPrize() external nonReentrant {
        if (!finalized) revert NotFinalized();

        uint256 amount = claimableWinnings[msg.sender];
        if (amount == 0) revert NoClaimableWinnings();

        claimableWinnings[msg.sender] = 0;
        hasClaimed[msg.sender] = true;
        totalClaimed += amount;

        usdc.safeTransfer(msg.sender, amount);

        emit PrizeClaimed(msg.sender, amount, totalClaimed, block.timestamp);
    }

    /**
     * @notice Emergency withdraw for participants if league is cancelled
     * @dev Only callable by admin when paused
     */
    function emergencyWithdraw() external nonReentrant whenPaused {
        if (!participants[msg.sender]) revert("Not a participant");
        if (finalized) revert AlreadyFinalized();

        participants[msg.sender] = false;
        usdc.safeTransfer(msg.sender, entryFee);

        emit EmergencyWithdraw(msg.sender, entryFee, block.timestamp);
    }

    /**
     * @notice Pause the league (admin only)
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the league (admin only)
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Set oracle address (admin only)
     * @param oracle Oracle address
     */
    function setOracle(address oracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ORACLE_ROLE, oracle);
    }

    /**
     * @notice Get all participants
     * @return Array of participant addresses
     */
    function getParticipants() external view returns (address[] memory) {
        return participantList;
    }

    /**
     * @notice Get prize distribution percentages
     * @return Array of percentages
     */
    function getPrizeDistribution() external view returns (uint256[] memory) {
        return prizeDistribution;
    }

    /**
     * @notice Validate prize distribution sums to 100
     * @param distribution Array of percentages
     * @return true if valid
     */
    function _validatePrizeDistribution(uint256[] memory distribution) private pure returns (bool) {
        return PrizeDistributor.validateDistribution(distribution);
    }

    /**
     * @notice Get participants ranked by FPL score
     * @return Sorted array of participant addresses (descending score)
     */
    function _getRankedParticipants() private view returns (address[] memory) {
        address[] memory ranked = new address[](participantList.length);
        for (uint256 i = 0; i < participantList.length; i++) {
            ranked[i] = participantList[i];
        }

        // Simple bubble sort (optimize for production)
        for (uint256 i = 0; i < ranked.length - 1; i++) {
            for (uint256 j = 0; j < ranked.length - i - 1; j++) {
                if (fplScores[ranked[j]] < fplScores[ranked[j + 1]]) {
                    address temp = ranked[j];
                    ranked[j] = ranked[j + 1];
                    ranked[j + 1] = temp;
                }
            }
        }

        return ranked;
    }

    /*//////////////////////////////////////////////////////////////
                        FRONTEND VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get comprehensive league information
     * @return LeagueInfo struct with all league details
     */
    function getLeagueInfo() external view returns (LeagueInfo memory) {
        return LeagueInfo({
            name: leagueName,
            creator: creator,
            entryFee: entryFee,
            prizePool: prizePool,
            startTime: startTime,
            endTime: endTime,
            participantCount: participantList.length,
            finalized: finalized,
            scoresUpdated: scoresUpdated,
            status: getLeagueStatus()
        });
    }

    /**
     * @notice Get current league status
     * @return Current LeagueStatus enum value
     */
    function getLeagueStatus() public view returns (LeagueStatus) {
        if (paused()) return LeagueStatus.Cancelled;
        if (block.timestamp < startTime) return LeagueStatus.NotStarted;
        if (block.timestamp >= endTime && finalized) return LeagueStatus.Finalized;
        if (block.timestamp >= endTime) return LeagueStatus.Ended;
        return LeagueStatus.Active;
    }

    /**
     * @notice Get participant information
     * @param participant Address of participant
     * @return ParticipantInfo struct with participant details
     */
    function getParticipantInfo(address participant) external view returns (ParticipantInfo memory) {
        return ParticipantInfo({
            participant: participant,
            score: fplScores[participant],
            rank: _getParticipantRank(participant),
            claimableWinnings: claimableWinnings[participant],
            hasClaimed: hasClaimed[participant]
        });
    }

    /**
     * @notice Get user stats (useful for UI state)
     * @param user Address to check
     * @return isParticipant Whether user has joined
     * @return score User's FPL score
     * @return rank User's rank (0 if not participant)
     * @return claimableAmount Claimable winnings
     * @return hasClaimedPrize Whether user has claimed
     * @return canJoin Whether user can join now
     * @return canClaim Whether user can claim now
     */
    function getUserStats(address user)
        external
        view
        returns (
            bool isParticipant,
            uint256 score,
            uint256 rank,
            uint256 claimableAmount,
            bool hasClaimedPrize,
            bool canJoin,
            bool canClaim
        )
    {
        isParticipant = participants[user];
        score = fplScores[user];
        rank = _getParticipantRank(user);
        claimableAmount = claimableWinnings[user];
        hasClaimedPrize = hasClaimed[user];

        LeagueStatus status = getLeagueStatus();
        canJoin = status == LeagueStatus.Active && !isParticipant;
        canClaim = finalized && claimableAmount > 0 && !hasClaimedPrize;
    }

    /**
     * @notice Get time remaining until league ends
     * @return Seconds remaining (0 if ended)
     */
    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= endTime) return 0;
        return endTime - block.timestamp;
    }

    /**
     * @notice Check if league is currently joinable
     * @return True if active and not paused
     */
    function isJoinable() external view returns (bool) {
        LeagueStatus status = getLeagueStatus();
        return status == LeagueStatus.Active;
    }

    /**
     * @notice Get prize breakdown (amounts and percentages)
     * @return amounts Array of prize amounts in USDC
     * @return percentages Array of prize percentages
     */
    function getPrizeBreakdown() external view returns (uint256[] memory amounts, uint256[] memory percentages) {
        amounts = new uint256[](prizeDistribution.length);
        percentages = prizeDistribution;

        for (uint256 i = 0; i < prizeDistribution.length; i++) {
            amounts[i] = (prizePool * prizeDistribution[i]) / 100;
        }
    }

    /**
     * @notice Get participant rank
     * @param participant Address to check
     * @return Rank (1-indexed), 0 if not a participant
     */
    function _getParticipantRank(address participant) private view returns (uint256) {
        if (!participants[participant]) return 0;

        address[] memory ranked = _getRankedParticipants();
        for (uint256 i = 0; i < ranked.length; i++) {
            if (ranked[i] == participant) {
                return i + 1;
            }
        }
        return 0;
    }
}
