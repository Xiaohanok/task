// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployNFTMarketplace is Script {
    function run() external {
        address paymentToken = address(0xaa5bc77916ce4a0e377F8F2bB9b0577798fE9beb);

        vm.startBroadcast();

        // 部署逻辑合约
        NFTMarketplace implementation = new NFTMarketplace();

        // 初始化 UUPS 代理
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(NFTMarketplace.initialize.selector, paymentToken)
        );

        vm.stopBroadcast();

        console.log("NFTMarketplace Proxy deployed at:", address(proxy));
        console.log("NFTMarketplace Proxy deployed at:", address(proxy));
    }
}