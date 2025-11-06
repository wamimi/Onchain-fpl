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

// Step 2: Query The Graph subgraph for league participants with FPL IDs
const SUBGRAPH_URL = "https://api.studio.thegraph.com/query/1713636/onchainfpl/v0.1.0";

const graphqlQuery = {
  query: `
    query GetParticipants($leagueId: Bytes!) {
      participants(where: { league: $leagueId, fplId_gt: 0 }) {
        address
        fplId
      }
    }
  `,
  variables: {
    leagueId: `0x${leagueAddress}`
  }
};

console.log(`Querying subgraph for league: 0x${leagueAddress}`);

let subgraphResponse;
try {
  const response = await Functions.makeHttpRequest({
    url: SUBGRAPH_URL,
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    data: graphqlQuery
  });

  if (response.error) {
    throw new Error(`Subgraph query failed: ${response.error}`);
  }

  subgraphResponse = response.data;
} catch (error) {
  console.log(`Subgraph query error: ${error.message}`);
  // Return empty result if subgraph is unavailable
  return Functions.encodeUint256(0);
}

if (!subgraphResponse.data || !subgraphResponse.data.participants) {
  console.log("No participant data in subgraph response");
  return Functions.encodeUint256(0);
}

const participants = subgraphResponse.data.participants.map(p => ({
  address: p.address,
  fplId: parseInt(p.fplId)
}));

if (!participants || participants.length === 0) {
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

// Step 5: ABI encode response as hex string
// Format: (address[], uint256[])
// Contract will decode as: abi.decode(response, (address[], uint256[]))

let response = "";

// Array length (32 bytes)
response += addresses.length.toString(16).padStart(64, '0');

// Addresses (20 bytes each, left-padded to 32 bytes)
addresses.forEach(addr => {
  const cleaned = addr.toLowerCase().replace('0x', '');
  response += cleaned.padStart(64, '0');
});

// Scores (32 bytes each)
scores.forEach(score => {
  response += score.toString(16).padStart(64, '0');
});

return Uint8Array.from(Buffer.from(response, 'hex'));
