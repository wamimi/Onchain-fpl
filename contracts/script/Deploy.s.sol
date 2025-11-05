// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LeagueFactory.sol";
import "../src/League.sol";

contract DeployScript is Script {
    // Official Circle USDC on Base Sepolia
    address constant USDC_BASE_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;

    function run() external {
        // Read environment variables
        string memory privateKeyHex = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKeyHex));

        // FPLOracle deployed address
        address oracle = 0x36915C4aFDd708e65DbABbA59193C34411C1d1d8;

        require(oracle != address(0), "Oracle address not set! Deploy FPLOracle first.");

        console.log("\n=== DEPLOYING LEAGUE FACTORY ===");
        console.log("Network: Base Sepolia (Chain ID: 84532)");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("FPLOracle:", oracle);
        console.log("USDC:", USDC_BASE_SEPOLIA);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy LeagueFactory
        console.log("\nDeploying LeagueFactory...");
        LeagueFactory factory = new LeagueFactory(USDC_BASE_SEPOLIA, oracle);
        console.log("  Deployed at:", address(factory));

        vm.stopBroadcast();

        // Deployment summary
        console.log("\n=================================================");
        console.log("      LEAGUE FACTORY DEPLOYED SUCCESSFULLY!      ");
        console.log("=================================================");
        console.log("\nDeployed Contracts:");
        console.log("  USDC (Circle):", USDC_BASE_SEPOLIA);
        console.log("  FPLOracle:    ", oracle);
        console.log("  LeagueFactory:", address(factory));
        console.log("\nNext Steps:");
        console.log("  1. Verify LeagueFactory on Basescan");
        console.log("  2. Test: Create a league via factory");
        console.log("  3. Update frontend with addresses");
        console.log("\nUseful Commands:");
        console.log("  Get total leagues:");
        console.log("    cast call", address(factory), '"getTotalLeagues()" --rpc-url $BASE_SEPOLIA_RPC_URL');
        console.log("  Create a league:");
        console.log("    cast send", address(factory), '"createLeague(string,uint256,uint256,uint256[])" ...');
        console.log("=================================================\n");
    }
}
