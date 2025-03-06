// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarketplace is Initializable, UUPSUpgradeable {
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool active;
    }
    address ow;

    IERC20 public paymentToken;
    mapping(address => mapping(uint256 => Listing)) public listings;

    event NFTListed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event NFTSold(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event NFTListingCanceled(address indexed seller, address indexed nftContract, uint256 indexed tokenId);

    function initialize(address _paymentToken) public initializer {
        ow = msg.sender;
        __UUPSUpgradeable_init();
        paymentToken = IERC20(_paymentToken);
    }

    function _authorizeUpgrade(address newImplementation) internal override  {
        require(msg.sender == ow,"no");
    }

    function listNFT(address nftContract, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            active: true
        });

        emit NFTListed(msg.sender, nftContract, tokenId, price);
    }

    function buyNFT(address nftContract, uint256 tokenId) external {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.active, "NFT not for sale");

        paymentToken.transferFrom(msg.sender, listing.seller, listing.price);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        listing.active = false;

        emit NFTSold(msg.sender, nftContract, tokenId, listing.price);
    }

    function cancelListing(address nftContract, uint256 tokenId) external {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.seller == msg.sender, "Not the seller");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        listing.active = false;

        emit NFTListingCanceled(msg.sender, nftContract, tokenId);
    }
}