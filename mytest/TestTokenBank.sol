// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ERC20.sol";  // 正确导入 BaseERC20 合约

contract BaseERC20Test is Test {
    BaseERC20 token;  // 声明 BaseERC20 类型的变量

    address public user1 = address(0x123);  // 测试用户1地址
    address public user2 = address(0x456);  // 测试用户2地址

    // 在每个测试之前调用 setUp 初始化合约
    function setUp() public {
        // 部署合约，合约部署后，部署者地址自动拥有所有的 token
        token = new BaseERC20();
    }

    function testInitialSupply() public view  {
        // 测试合约的初始供应量是否正确
        uint256 expectedSupply = 100000000 * 10**18;  // 100 million tokens with 18 decimals
        assertEq(token.totalSupply(), expectedSupply);
    }

    function testBalanceOf() public view {
        // 测试合约部署者的初始余额是否正确
        assertEq(token.balanceOf(address(this)), 100000000 * 10**18);  // 部署者应该有所有的代币
    }


    function testTransferFrom() public {
        // 测试授权转账功能
        uint256 transferAmount = 50 * 10**18;  // 授权 50 个 token

        // 授权 user2 从合约地址转账
        token.approve(user2, transferAmount);

        // 使用 user2 调用 transferFrom 来转账
        vm.prank(user2);  // 模拟 user2 作为调用者
        token.transferFrom(address(this), user1, transferAmount);

        // 验证余额是否更新
        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(address(this)), 100000000 * 10**18 - transferAmount);
    }

    function testAllowance() public {
        // 测试授权余额
        uint256 allowanceAmount = 200 * 10**18;  // 授权 200 个 token
        token.approve(user2, allowanceAmount);

        // 验证授权余额
        assertEq(token.allowance(address(this), user2), allowanceAmount);
    }

    function testApproveZeroAddress() public {
        // 测试授权时传递零地址
        vm.expectRevert("Invalid address");
        token.approve(address(0), 100 * 10**18);
    }


    function testTransferToZeroAddress() public {
        // 测试转账到零地址
        vm.expectRevert("Receiver should not be zero");
        token.transfer(address(0), 100 * 10**18);  // 转账到零地址
    }
}