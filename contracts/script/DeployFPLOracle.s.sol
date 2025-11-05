// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FPLOracle.sol";

contract DeployFPLOracle is Script {
    // Chainlink Functions configuration for Base Sepolia
    address constant ROUTER = 0xf9B8fc078197181C841c296C876945aaa425B278;
    bytes32 constant DON_ID = 0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000;
    uint32 constant GAS_LIMIT = 300000;

    function run() external {
        // Read environment variables
        string memory privateKeyHex = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKeyHex));
        uint64 subscriptionId = uint64(vm.envUint("SUBSCRIPTION_ID"));

        console.log("\n=== DEPLOYING FPL ORACLE ===");
        console.log("Network: Base Sepolia (Chain ID: 84532)");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("\nChainlink Configuration:");
        console.log("  Router:", ROUTER);
        console.log("  Subscription ID:", subscriptionId);
        console.log("  DON ID:", vm.toString(DON_ID));
        console.log("  Gas Limit:", GAS_LIMIT);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy FPLOracle
        console.log("\nDeploying FPLOracle...");
        FPLOracle oracle = new FPLOracle(
            ROUTER,
            subscriptionId,
            DON_ID,
            GAS_LIMIT
        );
        console.log("  Deployed at:", address(oracle));

        vm.stopBroadcast();

        // Deployment summary
        console.log("\n=================================================");
        console.log("         FPL ORACLE DEPLOYED SUCCESSFULLY!       ");
        console.log("=================================================");
        console.log("\nContract Address:");
        console.log("  FPLOracle:", address(oracle));
        console.log("\nNext Steps:");
        console.log("  1. Add oracle as consumer to Chainlink subscription");
        console.log("     Visit: https://functions.chain.link/base-sepolia/", subscriptionId);
        console.log("     Add consumer:", address(oracle));
        console.log("\n  2. Set JavaScript source code:");
        console.log("     Run: cast send", address(oracle));
        console.log("          'updateSource(string)' \"$(cat contracts/scripts/fpl-source.js)\"");
        console.log("          --private-key $PRIVATE_KEY --rpc-url $BASE_SEPOLIA_RPC_URL");
        console.log("\n  3. Deploy LeagueFactory with oracle address:");
        console.log("     Update Deploy.s.sol to use:", address(oracle));
        console.log("\n  4. Verify contract on Basescan");
        console.log("=================================================\n");
    }
}
