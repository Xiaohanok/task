// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {NFTMarketplacV2} from "../src/NFTMarketplacev2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";

contract UpgradeNFTMarketplace is Script {
    function run() external {

        vm.startBroadcast();

        // 部署新逻辑合约
        NFTMarketplacV2 newImplementation = new NFTMarketplacV2();


        vm.stopBroadcast();

        console.log("NFTMarketplace upgraded to V2 at:", address(newImplementation));
    }
}