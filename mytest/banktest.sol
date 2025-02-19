// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank bank;
    address user1 = address(0x1);
    uint256 depositAmount = 1 ether;

    // 在每个测试之前执行
    function setUp() public {
        bank = new Bank();
        // 给测试用户一些 ETH
        vm.deal(user1, 2 ether);
    }

    // 测试存款事件
    function testDepositEvent() public {
        vm.prank(user1);
        
        // 期望下一个调用会触发 Deposit 事件
        vm.expectEmit(true, false, false, true);
        emit Bank.Deposit(user1, depositAmount);
        
        bank.depositETH{value: depositAmount}();
    }

    // 测试存款后余额更新
    function testDepositBalance() public {
        // 检查初始余额为 0
        assertEq(bank.balanceOf(user1), 0);

        // 执行存款
        vm.prank(user1);
        bank.depositETH{value: depositAmount}();

        // 检查余额更新
        assertEq(bank.balanceOf(user1), depositAmount);
        // 检查合约 ETH 余额
        assertEq(address(bank).balance, depositAmount);
    }

    // 测试当存款金额为0时应该revert
    function test_RevertWhen_DepositZero() public {
        vm.prank(user1);
        vm.expectRevert("Deposit amount must be greater than 0");
        bank.depositETH{value: 0}();
    }
}
