// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {TokenBank} from "../src/TokenBankP.sol";
import {MyToken} from "../src/Mytoken.sol";
import {Permit2} from "../src/Permit2.sol";
import {ISignatureTransfer} from "../src/interfaces/ISignatureTransfer.sol";

contract TokenBankPTest is Test {
    TokenBank public tokenBank;
    MyToken public myToken;
    Permit2 public permit2;
    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");
    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );
    uint256 ownerPrivateKey = 0x123;

    address public user = vm.addr(ownerPrivateKey);
    uint256 public initialSupply = 1e18;
    bytes32 DOMAIN_SEPARATOR;

    function setUp() public {
        myToken = new MyToken("TestToken", "TTK");
        permit2 = new Permit2(); // 假设 Permit2 合约有默认构造函数
        tokenBank = new TokenBank(address(myToken), address(permit2));
        DOMAIN_SEPARATOR = permit2.DOMAIN_SEPARATOR();

        // 向用户转移一些代币
        myToken.transfer(user, initialSupply);
    }

    function testDepositWithPermit2() public {
        uint256 amount = 1e18; // 存款金额
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = 0;

        // 这里需要生成有效的签名
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(myToken), amount: initialSupply}),
            nonce: nonce,
            deadline: deadline
        });
        bytes32 tokenPermissions = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted));
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        _PERMIT_TRANSFER_FROM_TYPEHASH,
                        tokenPermissions,
                        address(tokenBank),
                        permit.nonce,
                        permit.deadline
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, msgHash);
        bytes memory signature = bytes.concat(r, s, bytes1(v));

        // 验证存款余额
        assertEq(tokenBank.balances(user), 0, "Balance should mach 0");

        // 用户调用 depositWithPermit2
        vm.startPrank(user);
        myToken.approve(address(permit2), 1e10 * 1e18);
        tokenBank.depositWithPermit2(user, amount, deadline, nonce, signature);
        vm.stopPrank();

        // 验证存款余额
        assertEq(tokenBank.balances(user), amount, "Balance should match the deposited amount");
    }
}
