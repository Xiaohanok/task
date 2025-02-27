// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/nftmarketp.sol";
import {GameItem} from "../src/ERC721.sol";
import {BaseERC20} from "../src/ERC20.sol";

contract TestMarketp is Test {
    NFTMarketplace market;
    GameItem nft;
    BaseERC20 token;
    uint256 ownerPrivateKey = 0x123;
    address admin = vm.addr(ownerPrivateKey);
    address user1 = makeAddr("user1");
    uint256 tokenId = 0;
    uint256 nonce = 0;
    uint256 price = 100 * 1e18; // 100 tokens
    uint256 deadline = type(uint256).max; // 设置为最大值
    uint8 v;
    bytes32 r;
    bytes32 s;

    function setUp() public {
        nft = new GameItem();
        vm.prank(user1);
        token = new BaseERC20();
        nft.awardItem(admin, "tokenURI"); // 铸造 NFT
        
        vm.startPrank(admin);
        market = new NFTMarketplace(address(token),address(nft));
        nft.approve(address(market), tokenId); // 授权市场合约
        market.list(tokenId, price); // 上架 NFT
        vm.stopPrank();
    }

    function testPermitBuy() public {
        // 1. approve nft
                // 2. 生成 permit hash
        bytes32 permitHash = keccak256(abi.encode(
            keccak256("Permit(address spender,uint256 tokenId,uint256 deadline,uint256 nonce)"),
            user1,
            tokenId,
            deadline,
            nonce
        ));

        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,address verifyingContract)"),
            keccak256(bytes("YourContract")),  // 合约的名称
            keccak256(bytes("1")),              // 版本
            address(market)                       // 当前合约地址
        ));



        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, permitHash));

        // 3. 使用私钥生成签名
        (v, r, s) = vm.sign(ownerPrivateKey, digest);

        vm.startPrank(user1);
        token.approve(address(market), price);    // 4. 调用 permit 方法
        market.permitBuy(user1, tokenId, deadline, nonce, v, r, s);
        vm.stopPrank();

        // 5. 验证授权
        assertEq(nft.ownerOf(tokenId), user1, "Allowance should be set correctly");
        
    }

}
