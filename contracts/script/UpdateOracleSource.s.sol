// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/FPLOracle.sol";

contract UpdateOracleSource is Script {
    address constant ORACLE = 0x36915C4aFDd708e65DbABbA59193C34411C1d1d8;

    function run() external {
        string memory privateKeyHex = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKeyHex));

        console.log("\n=== UPDATING FPL ORACLE SOURCE CODE ===");
        console.log("Oracle:", ORACLE);
        console.log("Owner:", vm.addr(deployerPrivateKey));

        // Read JavaScript source from file
        string memory source = vm.readFile("scripts/fpl-source.js");

        console.log("\nSource code loaded:");
        console.log("  Length:", bytes(source).length, "bytes");

        vm.startBroadcast(deployerPrivateKey);

        FPLOracle oracle = FPLOracle(ORACLE);
        oracle.updateSource(source);

        console.log("\nSource code updated successfully!");

        vm.stopBroadcast();

        console.log("\n=== VERIFICATION ===");
        console.log("You can verify the source was uploaded by calling:");
        console.log("  cast call", ORACLE, '"source()" --rpc-url $RPC_URL');
        console.log("\n=== NEXT STEPS ===");
        console.log("1. Test oracle by requesting scores for test league");
        console.log("2. Join test league and register FPL ID");
        console.log("3. Request scores update and verify subgraph integration");
    }
}
