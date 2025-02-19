// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test,console} from "forge-std/Test.sol";
import {NFTMarketplace} from "../src/nftmarket.sol";
import {BaseERC20} from "../src/ERC20V3.sol";
import {GameItem} from "../src/ERC721.sol";

contract nftMTest is Test {
    NFTMarketplace nftmarket;
    BaseERC20 token;
    GameItem nft;
    
    address admin;
    address user1;
    uint256 constant PRICE = 500e18; // 500 tokens
    uint256 constant NFT_ID = 0;

    function setUp() public {
        // 使用makeAddr生成admin地址
        admin = makeAddr("admin");
        user1 = makeAddr("user1");
        
        // 将测试合约调用者设置为admin
        vm.startPrank(admin);
        
        // 部署 ERC20 代币合约
        token = new BaseERC20();
        
        // 部署 NFT 合约
        nft = new GameItem();
        
        // 使用代币地址和NFT地址来部署市场合约
        nftmarket = new NFTMarketplace(address(token), address(nft));
        
        vm.stopPrank();
    }

    function testListAndBuyNFT() public {
        // 1. user1 铸造 NFT
        vm.startPrank(user1);
        nft.awardItem(user1, "tokenURI");
        
        // 2. user1 授权给市场合约
        nft.approve(address(nftmarket), NFT_ID);
        
        // 3. user1 上架 NFT
        nftmarket.list(NFT_ID, PRICE);

        (uint256 price, bool isListed,address seller) = nftmarket.listedNFTs(NFT_ID);
        console.log("Listed NFT price:", price);
        console.log("Listed NFT seller:", seller);
        console.log("NFT is listed:", isListed);
        console.log("NFT_ID:", NFT_ID);
        vm.stopPrank();

        // 4. admin 授权代币给市场合约
        vm.startPrank(admin);

        token.approve(address(nftmarket), 600e18);
        
        // 5. admin 购买 NFT
        nftmarket.buyNFT(NFT_ID);
        vm.stopPrank();
        // 6. 断言检查
        // 检查 NFT 所有权是否转移给了 admin
        assertEq(nft.ownerOf(NFT_ID), admin);
        // 检查 user1 是否收到了代币
    }
        function test_RevertWhen_ListWithoutApproval() public {
        // 1. user1 铸造 NFT
        vm.prank(user1);
        nft.awardItem(user1, "tokenURI");
        
        // 2. 不进行授权，直接尝试上架
        vm.prank(admin);
        vm.expectRevert("You must be the owner to list this NFT");
        nftmarket.list(NFT_ID, PRICE);
    }

    function testSuccessfulNFTListing() public {
        // 1. user1 铸造 NFT
        vm.startPrank(user1);
        nft.awardItem(user1, "tokenURI");
        
        // 2. user1 授权给市场合约
        nft.approve(address(nftmarket), NFT_ID);
        
        // 3. user1 上架 NFT
        nftmarket.list(NFT_ID, PRICE);

        // 4. 验证上架后的状态
        assertEq(nft.ownerOf(NFT_ID), user1, "NFT should still belong to user1");
        assertEq(nft.getApproved(NFT_ID), address(nftmarket), "Market should be approved for NFT");
        
        (uint256 price, bool isListed, address seller) = nftmarket.listedNFTs(NFT_ID);
        assertEq(seller, user1, "Seller should be user1");
        assertEq(price, PRICE, "Price should match listing price");
        assertTrue(isListed, "NFT should be listed");
        
        vm.stopPrank();
    }

        function test_RevertWhen_BuyingSoldNFT() public {
        // 1. user1 铸造并上架 NFT
        vm.startPrank(user1);
        nft.awardItem(user1, "tokenURI");
        nft.approve(address(nftmarket), NFT_ID);
        nftmarket.list(NFT_ID, PRICE);
        vm.stopPrank();

        // 2. admin 首次购买 NFT
        vm.startPrank(admin);
        token.approve(address(nftmarket), PRICE);
        nftmarket.buyNFT(NFT_ID);
        
        // 3. 验证首次购买成功
        assertEq(nft.ownerOf(NFT_ID), admin, "NFT should be owned by admin");
        assertEq(token.balanceOf(user1), PRICE, "Seller should receive payment");

        // 4. 另一个用户尝试购买同一个 NFT
        address user2 = makeAddr("user2");
        vm.stopPrank();
        
        vm.startPrank(user2);
        token.approve(address(nftmarket), PRICE);
        
        // 5. 验证重复购买会失败
        vm.expectRevert("NFT is not listed for sale");
        nftmarket.buyNFT(NFT_ID);
        vm.stopPrank();

        // 6. 验证 NFT 所有权未变
        assertEq(nft.ownerOf(NFT_ID), admin, "NFT should still be owned by admin");
    }
    
    function test_RevertWhen_BuyingOwnNFT() public {
        // 1. user1 铸造并上架 NFT
        vm.startPrank(user1);
        nft.awardItem(user1, "tokenURI");
        nft.approve(address(nftmarket), NFT_ID);
        nftmarket.list(NFT_ID, PRICE);
        
        // 记录初始状态
        (uint256 initialPrice, bool initialListed, address initialSeller) = nftmarket.listedNFTs(NFT_ID);
        uint256 initialBalance = token.balanceOf(user1);
        
        // 2. user1 尝试购买自己的 NFT
        token.approve(address(nftmarket), PRICE);
        vm.expectRevert("Cannot buy your own NFT");
        nftmarket.buyNFT(NFT_ID);
        vm.stopPrank();
        
        // 3. 验证所有状态都未改变
        (uint256 finalPrice, bool finalListed, address finalSeller) = nftmarket.listedNFTs(NFT_ID);
        assertEq(nft.ownerOf(NFT_ID), user1, "NFT ownership should not change");
        assertEq(token.balanceOf(user1), initialBalance, "Token balance should not change");
        assertEq(finalPrice, initialPrice, "Price should not change");
        assertEq(finalListed, initialListed, "Listed status should not change");
        assertEq(finalSeller, initialSeller, "Seller should not change");
    }

    function testFuzz_ListAndBuyNFT(uint256 price, address buyer) public {
        // 约束条件
        vm.assume(price >= 0.01 ether && price <= 10000 ether);  // 价格在0.01-10000范围内
        vm.assume(buyer != address(0));                          // 买家地址不为0
        vm.assume(buyer != user1);                              // 买家不是卖家
        vm.assume(buyer != address(nftmarket));                 // 买家不是市场合约

        // 1. user1 铸造并上架 NFT
        vm.startPrank(user1);
        nft.awardItem(user1, "tokenURI");
        nft.approve(address(nftmarket), NFT_ID);
        nftmarket.list(NFT_ID, price);
        
        // 记录上架状态
        (uint256 listedPrice, bool isListed, address seller) = nftmarket.listedNFTs(NFT_ID);
        assertEq(listedPrice, price, "Listed price should match input");
        assertTrue(isListed, "NFT should be listed");
        assertEq(seller, user1, "Seller should be user1");
        vm.stopPrank();

        // 2. 给买家足够的代币
        vm.startPrank(admin);
        token.transfer(buyer, price);
        vm.stopPrank();

        // 3. 买家购买 NFT
        vm.startPrank(buyer);
        uint256 buyerInitialBalance = token.balanceOf(buyer);
        uint256 sellerInitialBalance = token.balanceOf(user1);
        
        token.approve(address(nftmarket), price);
        nftmarket.buyNFT(NFT_ID);

        // 4. 验证交易结果
        // 检查 NFT 所有权
        assertEq(nft.ownerOf(NFT_ID), buyer, "NFT should be transferred to buyer");
        
        // 检查代币转移
        assertEq(token.balanceOf(buyer), buyerInitialBalance - price, "Buyer's token balance incorrect");
        assertEq(token.balanceOf(user1), sellerInitialBalance + price, "Seller's token balance incorrect");
        
        // 检查NFT上架状态
        (,bool stillListed,) = nftmarket.listedNFTs(NFT_ID);
        assertFalse(stillListed, "NFT should not be listed after sale");
        
        vm.stopPrank();
    }
}
