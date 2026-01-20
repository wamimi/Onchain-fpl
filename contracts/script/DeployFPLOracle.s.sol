// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FPLOracle.sol";

contract DeployFPLOracle is Script {
    // Chainlink Functions configuration
    uint32 constant GAS_LIMIT = 300000;

    // Base Sepolia (Chain ID: 84532)
    address constant ROUTER_SEPOLIA = 0xf9B8fc078197181C841c296C876945aaa425B278;
    bytes32 constant DON_ID_SEPOLIA = 0x66756e2d626173652d7365706f6c69612d310000000000000000000000000000; // fun-base-sepolia-1

    // Base Mainnet (Chain ID: 8453)
    address constant ROUTER_MAINNET = 0xf9B8fc078197181C841c296C876945aaa425B278;
    bytes32 constant DON_ID_MAINNET = 0x66756e2d626173652d6d61696e6e65742d310000000000000000000000000000; // fun-base-mainnet-1

    function run() external {
        // Read environment variables
        string memory privateKeyHex = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKeyHex));
        uint64 subscriptionId = uint64(vm.envUint("SUBSCRIPTION_ID"));

        // Get network configuration based on chain ID
        uint256 chainId = block.chainid;
        (address router, bytes32 donId, string memory networkName, string memory functionsUrl) = getNetworkConfig(chainId);

        console.log("\n=== DEPLOYING FPL ORACLE ===");
        console.log("Network:", networkName);
        console.log("Chain ID:", chainId);
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("\nChainlink Configuration:");
        console.log("  Router:", router);
        console.log("  Subscription ID:", subscriptionId);
        console.log("  DON ID:", vm.toString(donId));
        console.log("  Gas Limit:", GAS_LIMIT);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy FPLOracle
        console.log("\nDeploying FPLOracle...");
        FPLOracle oracle = new FPLOracle(
            router,
            subscriptionId,
            donId,
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
        console.log("     Visit:", functionsUrl, subscriptionId);
        console.log("     Add consumer:", address(oracle));
        console.log("\n  2. Set JavaScript source code:");
        console.log("     Run: cast send", address(oracle));
        console.log("          'updateSource(string)' \"$(cat contracts/scripts/fpl-source.js)\"");
        console.log("          --private-key $PRIVATE_KEY --rpc-url $RPC_URL");
        console.log("\n  3. Deploy LeagueFactory with oracle address:");
        console.log("     Update Deploy.s.sol to use:", address(oracle));
        console.log("\n  4. Verify contract on Basescan");
        console.log("=================================================\n");
    }

    function getNetworkConfig(uint256 chainId) internal pure returns (
        address router,
        bytes32 donId,
        string memory networkName,
        string memory functionsUrl
    ) {
        if (chainId == 84532) {
            // Base Sepolia
            return (
                ROUTER_SEPOLIA,
                DON_ID_SEPOLIA,
                "Base Sepolia",
                "https://functions.chain.link/base-sepolia/"
            );
        } else if (chainId == 8453) {
            // Base Mainnet
            return (
                ROUTER_MAINNET,
                DON_ID_MAINNET,
                "Base Mainnet",
                "https://functions.chain.link/base/"
            );
        } else {
            revert("Unsupported network. Use Base Sepolia (84532) or Base Mainnet (8453)");
        }
    }
}
