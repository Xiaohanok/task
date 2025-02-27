// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MyToken} from "../src/ERC20P.sol";
import {TokenBank} from "../src/TokenBankp.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TestERC20P is Test {
    MyToken token;
    ERC20Permit Eermit;
    address owner = makeAddr("admin");
    address spender = address(0x2);
    uint256 amount = 100 * 1e18; // 100 tokens
    uint256 deadline = type(uint256).max; // 设置为最大值
    uint256 ownerPrivateKey = 0x123;
    uint8 v;
    bytes32 r;
    bytes32 s;

    function setUp() public {
        // 使用私钥生成地址
        owner = vm.addr(ownerPrivateKey);
        token = new MyToken("MyToken", "MTK");
        // 先铸造一些代币给 owner
        token.mint(owner, amount);
    }

    function testPermit() public {
        // 1. 获取 nonce
        uint256 nonce = token.nonces(owner);

        // 2. 生成 permit hash
        bytes32 permitHash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
            owner,
            spender,
            amount,
            nonce,
            deadline
        ));

        // 打印 DOMAIN_SEPARATOR
        console.logBytes32(token.DOMAIN_SEPARATOR());
        // 打印 ownerPrivateKey 转换为 bytes32
        console.logBytes32(bytes32(ownerPrivateKey));
        console.log(owner);

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), permitHash));

        // 3. 使用私钥生成签名
        (v, r, s) = vm.sign(ownerPrivateKey, digest);

        // 4. 调用 permit 方法
        token.permit(owner, spender, amount, deadline, v, r, s);

        // 5. 验证授权
        assertEq(token.allowance(owner, spender), amount, "Allowance should be set correctly");
        assertEq(token.nonces(owner), nonce + 1, "Nonce should be incremented");
    }

}
