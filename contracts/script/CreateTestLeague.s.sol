// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LeagueFactory.sol";

contract CreateTestLeague is Script {
    address constant FACTORY = 0x1E3Ef2263e964Cff21Bd3F9e4eB7D2D8385FE690;

    function run() external {
        string memory privateKeyHex = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKeyHex));

        console.log("\n=== CREATING TEST LEAGUE ===");
        console.log("Factory:", FACTORY);
        console.log("Creator:", vm.addr(deployerPrivateKey));

        // League parameters
        string memory name = "Test League - Subgraph Verification";
        uint256 entryFee = 10 * 10**6; // 10 USDC
        uint256 duration = 7 days;
        uint256[] memory prizePercentages = new uint256[](3);
        prizePercentages[0] = 50; // 50% for 1st place
        prizePercentages[1] = 30; // 30% for 2nd place
        prizePercentages[2] = 20; // 20% for 3rd place

        vm.startBroadcast(deployerPrivateKey);

        LeagueFactory factory = LeagueFactory(FACTORY);
        address leagueAddress = factory.createLeague(
            name,
            entryFee,
            duration,
            prizePercentages
        );

        console.log("\nLeague Created!");
        console.log("  Address:", leagueAddress);
        console.log("  Name:", name);
        console.log("  Entry Fee:", entryFee / 10**6, "USDC");
        console.log("  Duration:", duration / 1 days, "days");

        vm.stopBroadcast();

        console.log("\n=== VERIFICATION STEPS ===");
        console.log("1. Wait 1-2 minutes for subgraph to index the new league");
        console.log("2. Go to: https://api.studio.thegraph.com/query/1713636/onchainfpl/v0.1.0");
        console.log("3. Run this query to see your new league:");
        console.log("");
        console.log("{");
        console.log("  leagues(first: 1, orderBy: createdAt, orderDirection: desc) {");
        console.log("    id");
        console.log("    name");
        console.log("    creator");
        console.log("    entryFee");
        console.log("    startTime");
        console.log("    endTime");
        console.log("  }");
        console.log("}");
        console.log("");
        console.log("Expected league address:", leagueAddress);
    }
}
