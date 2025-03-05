// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTMarket  {
    address public constant ETH_FLAG = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    string  public constant name     = "Nft list";
    string  public constant version  = "1";
    bytes32 public  DOMAIN_SEPARATOR = keccak256(abi.encode(
    keccak256("EIP712Domain(string name,string version,address ver,uint256 chainid)"),
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        address(this),
        11155111
    ));
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address nft,uint256 id,address paytoken,uint256 price)");





    function buy(address nft,uint256 tokenId, address paytoken,uint256 price , uint8 v, bytes32 r, bytes32 s) public payable {

        bytes32 digest =keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR,keccak256(abi.encode(PERMIT_TYPEHASH,nft,paytoken,tokenId,price))));
        address signer = ecrecover(digest, v, r, s);
        require(IERC721(nft).ownerOf(tokenId) == signer, "wrong sign");

        if (paytoken == ETH_FLAG) {
            require(msg.value == price, "MKT: wrong eth value");
            (bool success,) = signer.call{value: price}("");
            require(success, "MKT: transfer failed");

        } else {
            require(msg.value == 0, "MKT: wrong eth value");
            SafeERC20.safeTransferFrom(IERC20(paytoken), msg.sender, signer, price);
        }

        IERC721(nft).safeTransferFrom(signer, msg.sender, tokenId);
        emit Sold(signer, msg.sender, price);

        //检验nft是否上架 签名者是否拥有nft 
        //检查转的eth 是等于出售价格
        //将eth转给卖家
        //将nft转给买家
    }

    event Sold(address from, address to, uint256 price);

}
