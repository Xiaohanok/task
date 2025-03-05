// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "forge-std/console.sol"; 
import "../src/ERC721.sol"; // 确保路径正确
import "../src/nftmarketv2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1000 * 10 ** decimals()); // 初始铸造1000个代币给合约创建者
    }
}

contract NFTMarketV2Test is Test {
    NFTMarket market;
    GameItem nft;
    MockERC20 mockToken;

    uint256 ownerPrivateKey = 0x123;
    address sell;
    address buy;
    bytes32 public  DOMAIN_SEPARATOR1;
    string  public constant version  = "1";
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address nft,uint256 id,address paytoken,uint256 price)");
    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);



    function setUp() public {
        // 部署 NFTMarket 合约
        market = new NFTMarket();
        nft = new GameItem();
        sell = vm.addr(ownerPrivateKey);
        buy = address(0x123);
        vm.deal(buy, 2 ether); // 给用户足够的 ETH
        vm.deal(address(this), 2 ether); // 给测试合约足够的 ETH
        vm.prank(buy);
        mockToken = new MockERC20();
    }

    function testBuyWithETH() public {

         // 1. 铸造 NFT
        string memory tokenURI = "https://example.com/token/0";
        uint256 tokenId = nft.awardItem(sell, tokenURI);
        console.log(tokenId);
        vm.startPrank(sell);
        nft.approve(address(market), tokenId);

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, address(nft),ETH_FLAG, tokenId,1 ether));
        DOMAIN_SEPARATOR1 = keccak256(abi.encode(keccak256("EIP712Domain(string name,string version,address ver,uint256 chainid)"),keccak256(bytes("Nft list")),keccak256(bytes(version)),address(market),11155111
    ));
        // 3. 签名购买信息
        bytes32 digest =keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR1,structHash));
                        
 
        (uint8 v, bytes32 r, bytes32 s) = vm.sign( ownerPrivateKey ,digest);
        vm.stopPrank();
         // 记录卖家购买前的 ETH 余额
        uint256 initialBalance = address(sell).balance;

        // 4. 用户购买 NFT
        vm.startPrank(buy); // 设置用户为调用者
        market.buy{value: 1 ether}(address(nft), tokenId, market.ETH_FLAG(), 1 ether, v, r, s);
        vm.stopPrank();

                // 5. 验证用户是否成功购买了 NFT
        assertEq(nft.ownerOf(tokenId), buy);
        uint256 finalBalance = address(sell).balance;
        assertEq(finalBalance, initialBalance + 1 ether); // 验证卖家没有收到 ETH，因为是用 ERC20 购买
        



        // 验证用户是否成功购买了 NFT
        // 例如：assertEq(IERC721(nftAddress).ownerOf(tokenId), user);
    }

    function testBuyWithERC20() public {
        // 1. 铸造 NFT
        string memory tokenURI = "https://example.com/token/1";
        uint256 tokenId = nft.awardItem(sell, tokenURI);
        console.log(tokenId);
        
        // 2. 用户批准市场合约使用其 ERC20 代币
        vm.startPrank(sell);
        nft.approve(address(market), tokenId); // 批准市场合约使用 NFT


        // 3. 签名上架信息
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, address(nft),address(mockToken),tokenId, 1 ether));
        DOMAIN_SEPARATOR1 = keccak256(abi.encode(keccak256("EIP712Domain(string name,string version,address ver,uint256 chainid)"), keccak256(bytes("Nft list")), keccak256(bytes(version)), address(market),11155111));
        
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR1, structHash));

        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        vm.stopPrank();

        // 记录卖家购买前的 token 余额
        uint256 initialBalance = mockToken.balanceOf(sell);

        // 4. 用户使用 ERC20 购买 NFT
        vm.startPrank(buy); // 设置用户为调用者
        mockToken.approve(address(market), 1 ether);
        market.buy{value: 0}(address(nft), tokenId, address(mockToken), 1 ether, v, r, s); // 使用 ERC20 代币购买
        vm.stopPrank();

        // 5. 验证用户是否成功购买了 NFT
        assertEq(nft.ownerOf(tokenId), buy);

        uint256 finalBalance = mockToken.balanceOf(sell);
        assertEq(finalBalance, initialBalance + 1 ether); // 验证卖家没有收到 ETH，因为是用 ERC20 购买
    }
}
