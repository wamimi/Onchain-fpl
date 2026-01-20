// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FPLOracle.sol";

contract UpdateOracleSource is Script {
    // Deployed FPLOracle addresses
    address constant ORACLE_BASE_SEPOLIA = 0x36915C4aFDd708e65DbABbA59193C34411C1d1d8;
    address constant ORACLE_BASE_MAINNET = 0x5495cEb2Dd933661309c91525CdFFE4b579c9104;

    function run() external {
        string memory privateKeyHex = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKeyHex));

        // Get oracle address based on chain ID
        uint256 chainId = block.chainid;
        (address oracleAddress, string memory networkName) = getNetworkConfig(chainId);

        console.log("\n=== UPDATING FPL ORACLE SOURCE CODE ===");
        console.log("Network:", networkName);
        console.log("Oracle:", oracleAddress);
        console.log("Owner:", vm.addr(deployerPrivateKey));

        // Read JavaScript source from file
        string memory source = vm.readFile("scripts/fpl-source.js");

        console.log("\nSource code loaded:");
        console.log("  Length:", bytes(source).length, "bytes");

        vm.startBroadcast(deployerPrivateKey);

        FPLOracle oracle = FPLOracle(oracleAddress);
        oracle.updateSource(source);

        console.log("\nSource code updated successfully!");

        vm.stopBroadcast();

        console.log("\n=== VERIFICATION ===");
        console.log("You can verify the source was uploaded by calling:");
        console.log("  cast call", oracleAddress, '"source()" --rpc-url $RPC_URL');
        console.log("\n=== NEXT STEPS ===");
        console.log("1. Deploy LeagueFactory if not already deployed");
        console.log("2. Test oracle by requesting scores for a league");
    }

    function getNetworkConfig(uint256 chainId) internal pure returns (
        address oracleAddress,
        string memory networkName
    ) {
        if (chainId == 84532) {
            return (ORACLE_BASE_SEPOLIA, "Base Sepolia");
        } else if (chainId == 8453) {
            return (ORACLE_BASE_MAINNET, "Base Mainnet");
        } else {
            revert("Unsupported network. Use Base Sepolia (84532) or Base Mainnet (8453)");
        }
    }
}
