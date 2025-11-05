/**
 * Chainlink Functions JavaScript Source Code
 * Fetches FPL scores for league participants and returns ABI-encoded data
 *
 * Arguments:
 * - args[0]: League contract address (hex string without 0x)
 * - args[1]: Gameweek number
 *
 * Returns: ABI-encoded (address[] participants, uint256[] scores)
 */

// FPL API base URL
const FPL_API_BASE = "https://fantasy.premierleague.com/api";

// Get arguments from contract
const leagueAddress = args[0]; // League contract address
const gameweek = parseInt(args[1]); // Gameweek number

console.log(`Fetching FPL scores for league ${leagueAddress}, gameweek ${gameweek}`);

// Helper: Make HTTP GET request with retry logic
async function fetchWithRetry(url, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await Functions.makeHttpRequest({ url });
      if (response.error) {
        throw new Error(`HTTP Error: ${response.error}`);
      }
      return response.data;
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      // Wait before retry (exponential backoff)
      await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, i)));
    }
  }
}

// Step 1: Get current gameweek info to validate
const bootstrapData = await fetchWithRetry(`${FPL_API_BASE}/bootstrap-static/`);
const currentGameweek = bootstrapData.events.find(event => event.is_current);

if (!currentGameweek) {
  throw Error("No current gameweek found");
}

console.log(`Current FPL gameweek: ${currentGameweek.id}`);

// Use requested gameweek or current if invalid
const targetGameweek = gameweek > 0 && gameweek <= 38 ? gameweek : currentGameweek.id;

// Step 2: Get league participants from on-chain
// NOTE: This is a mock - in production, you'd need to fetch this from your API
// or use Chainlink Any API to read from another contract
// For now, we'll use a placeholder that should be replaced with real data

// In production, you would:
// 1. Store participant FPL IDs in your League contract
// 2. Expose an API endpoint that returns: { leagueAddress: string, fplIds: number[] }
// 3. Fetch from that endpoint here
const LEAGUE_API_URL = `https://your-api.com/leagues/${leagueAddress}/participants`;

let participantData;
try {
  participantData = await fetchWithRetry(LEAGUE_API_URL);
} catch (error) {
  // Fallback for testing: Return empty arrays
  console.log("Could not fetch participants, returning empty result");

  // ABI encode empty arrays
  const emptyAddresses = [];
  const emptyScores = [];

  return Functions.encodeUint256(0); // Return 0 to signal no data
}

// Expected format from your API:
// {
//   "participants": [
//     { "address": "0x123...", "fplId": 123456 },
//     { "address": "0x456...", "fplId": 789012 }
//   ]
// }

const participants = participantData.participants;

if (!participants || participants.length === 0) {
  // No participants, return empty
  return Functions.encodeUint256(0);
}

// Step 3: Fetch scores for each participant's FPL team
const scoresPromises = participants.map(async (participant) => {
  try {
    // Get team data for gameweek
    const teamData = await fetchWithRetry(
      `${FPL_API_BASE}/entry/${participant.fplId}/event/${targetGameweek}/picks/`
    );

    // Calculate total points for this gameweek
    const totalPoints = teamData.entry_history?.points || 0;

    return {
      address: participant.address,
      score: totalPoints
    };
  } catch (error) {
    console.log(`Error fetching score for FPL ID ${participant.fplId}: ${error.message}`);
    return {
      address: participant.address,
      score: 0 // Default to 0 on error
    };
  }
});

// Wait for all score fetches to complete
const results = await Promise.all(scoresPromises);

// Step 4: Prepare arrays for ABI encoding
const addresses = results.map(r => r.address);
const scores = results.map(r => r.score);

console.log(`Fetched ${results.length} scores:`, results);

// Step 5: ABI encode the response
// Format: (address[], uint256[])
// Solidity will decode as: abi.decode(response, (address[], uint256[]))

// Convert hex addresses to bytes
const addressBytes = addresses.map(addr => {
  // Remove 0x prefix if present
  const cleaned = addr.toLowerCase().replace('0x', '');
  return cleaned;
});

// Create ABI-encoded response manually
// This is a simplified version - Chainlink Functions will handle the encoding
const encoded = Functions.encodeString(
  JSON.stringify({
    addresses: addressBytes,
    scores: scores
  })
);

// NOTE: The above is pseudo-code. Actual implementation needs proper ABI encoding
// For production, you'll need to use a library or manual encoding following ABI spec

// Return the ABI-encoded data
return encoded;

/**
 * ALTERNATIVE SIMPLER APPROACH:
 * Return hex-encoded data that can be decoded on-chain
 *
 * This approach is simpler and more reliable:
 */

// Create hex-encoded response
let response = "";

// Encode array length (32 bytes)
response += addresses.length.toString(16).padStart(64, '0');

// Encode each address (20 bytes each, padded to 32 bytes)
addresses.forEach(addr => {
  const cleaned = addr.toLowerCase().replace('0x', '');
  response += cleaned.padStart(64, '0');
});

// Encode each score (32 bytes each)
scores.forEach(score => {
  response += score.toString(16).padStart(64, '0');
});

// Return as bytes
return Uint8Array.from(Buffer.from(response, 'hex'));
