// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
}
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTMarketplace {
    IERC20 public token;  // ERC20 Token 地址
    IERC721 public nft;   // ERC721 NFT 地址
    address public owner1;

    // NFT 上架结构体
    struct ListedNFT {
        uint256 price;
        bool isListed;
        address seller;  // 存储卖家的地址
    }

    // 存储每个 NFT 的上架信息
    mapping(uint256 => ListedNFT) public listedNFTs;
    mapping(address account => uint256) public nonces;

    // 合约构造函数，接受 ERC20 Token 地址和 ERC721 NFT 地址
    constructor(address _token, address _nft) {
        token = IERC20(_token);
        nft = IERC721(_nft);
        owner1 = msg.sender;
    }

    // 上架 NFT
    function list(uint256 tokenId, uint256 price) external {
        // 确保调用者是 NFT 的所有者
        address owner = nft.ownerOf(tokenId);
        require(msg.sender == owner, "You must be the owner to list this NFT");

        // 确保价格大于 0
        require(price > 0, "Price must be greater than 0");

        // 确保 NFT 没有被上架
        ListedNFT storage listedNFT = listedNFTs[tokenId];
        require(!listedNFT.isListed, "NFT is already listed");

        // 更新映射，保存上架信息
        listedNFT.price = price;
        listedNFT.isListed = true;
        listedNFT.seller = msg.sender;  // 存储卖家的地址
    }

    // 购买 NFT
    function buyNFT(uint256 tokenId) internal {
        // 确保 NFT 已上架
        ListedNFT storage listedNFT = listedNFTs[tokenId];
        require(listedNFT.isListed, "NFT is not listed for sale");
        
        // 确保买家不是卖家
        require(msg.sender != listedNFT.seller, "Cannot buy your own NFT");

        // 确保买家支付足够的 ERC20 代币
        uint256 price = listedNFT.price;
        require(token.transferFrom(msg.sender, listedNFT.seller, price), "Payment failed");

        // 转移 NFT 到买家
        nft.transferFrom(listedNFT.seller, msg.sender, tokenId);

        // 标记 NFT 为已售出
        listedNFT.isListed = false;
    }

// 处理 NFT 购买
function tokensReceived(address from, uint256 _value, uint256 id) external {
    // 获取 NFT 的卖家地址和卖家的价格
    address seller = listedNFTs[id].seller;
    uint256 price = listedNFTs[id].price;
    
    // 确保该 NFT 已上架（isListed 为 true）
    require(listedNFTs[id].isListed, "NFT is not listed for sale");

    // 确保触发该函数的地址是正确的 token 地址
    require(msg.sender == address(token), "Invalid token");

    // 1. 验证转入的金额是否等于卖家要求的价格
    require(_value == price, "Incorrect value sent");


    // 3. 将代币从合约转移到卖家
    token.transfer(seller, _value);
    

    // 4. 将 NFT 从卖家地址转移给买家
    nft.transferFrom(seller, from, id); // 从卖家的地址到买家的地址

    // 5. 将 NFT 上架状态改为 false（表示该 NFT 已售出）
    listedNFTs[id].isListed = false;
}
// 编码函数，将id编码为data
    function permitBuy(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp < deadline, "Permit expired");

        bytes32 structHash = keccak256(abi.encode(
            keccak256("Permit(address spender,uint256 tokenId,uint256 deadline,uint256 nonce)"),
            spender,
            tokenId,
            deadline,
            nonce
        ));
        require(nonce == nonces[msg.sender],"nonce false");
        require(spender == msg.sender,"no");/// @title A title that should describe the contract/interface


        // 调用自定义的 _hashTypedDataV4 函数
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner1, "Invalid signature");
        nonces[msg.sender] +=1;

        buyNFT(tokenId);
    }

        // 自定义实现 _hashTypedDataV4 函数
    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        // 根据 EIP-712 规范构建域分隔符
        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,address verifyingContract)"),
            keccak256(bytes("YourContract")),  // 合约的名称
            keccak256(bytes("1")),              // 版本
            address(this)                       // 当前合约地址
        ));

        // 计算最终的哈希值：`hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash))`
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
    

}