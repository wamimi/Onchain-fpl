// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/LeagueFactory.sol";
import "../src/League.sol";

contract DeployScript is Script {
    // Official Circle USDC addresses
    address constant USDC_BASE_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant USDC_BASE_MAINNET = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // Deployed FPLOracle addresses (update after deploying FPLOracle to each network)
    address constant ORACLE_BASE_SEPOLIA = 0x36915C4aFDd708e65DbABbA59193C34411C1d1d8;
    address constant ORACLE_BASE_MAINNET = 0x5495cEb2Dd933661309c91525CdFFE4b579c9104;

    function run() external {
        // Read environment variables
        string memory privateKeyHex = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKeyHex));

        // Get network configuration based on chain ID
        uint256 chainId = block.chainid;
        (address usdc, address oracle, string memory networkName) = getNetworkConfig(chainId);

        require(oracle != address(0), "Oracle address not set! Deploy FPLOracle first and update ORACLE_BASE_MAINNET.");

        console.log("\n=== DEPLOYING LEAGUE FACTORY ===");
        console.log("Network:", networkName);
        console.log("Chain ID:", chainId);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("FPLOracle:", oracle);
        console.log("USDC:", usdc);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy LeagueFactory
        console.log("\nDeploying LeagueFactory...");
        LeagueFactory factory = new LeagueFactory(usdc, oracle);
        console.log("  Deployed at:", address(factory));

        vm.stopBroadcast();

        // Deployment summary
        console.log("\n=================================================");
        console.log("      LEAGUE FACTORY DEPLOYED SUCCESSFULLY!      ");
        console.log("=================================================");
        console.log("\nDeployed Contracts:");
        console.log("  USDC (Circle):", usdc);
        console.log("  FPLOracle:    ", oracle);
        console.log("  LeagueFactory:", address(factory));
        console.log("\nNext Steps:");
        console.log("  1. Verify LeagueFactory on Basescan");
        console.log("  2. Test: Create a league via factory");
        console.log("  3. Update frontend with addresses");
        console.log("\nUseful Commands:");
        console.log("  Get total leagues:");
        console.log("    cast call", address(factory), '"getTotalLeagues()" --rpc-url $RPC_URL');
        console.log("  Create a league:");
        console.log("    cast send", address(factory), '"createLeague(string,uint256,uint256,uint256[])" ...');
        console.log("=================================================\n");
    }

    function getNetworkConfig(uint256 chainId) internal pure returns (
        address usdc,
        address oracle,
        string memory networkName
    ) {
        if (chainId == 84532) {
            // Base Sepolia
            return (USDC_BASE_SEPOLIA, ORACLE_BASE_SEPOLIA, "Base Sepolia");
        } else if (chainId == 8453) {
            // Base Mainnet
            return (USDC_BASE_MAINNET, ORACLE_BASE_MAINNET, "Base Mainnet");
        } else {
            revert("Unsupported network. Use Base Sepolia (84532) or Base Mainnet (8453)");
        }
    }
}
