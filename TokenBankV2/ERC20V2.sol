// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 引入 ERC20 接口
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenBank {
    // 定义 ERC20 Token 的地址
    IERC20 public token;

    // 存储每个地址存入的 Token 数量
    mapping(address => uint256) public balances;

    // 合约构造函数，接受一个 ERC20 Token 地址
    constructor(address _token) {
        token = IERC20(_token);
    }

    // 存入 Token
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");

        // 从用户账户转移 Token 到 TokenBank 合约
        token.transferFrom(msg.sender, address(this), amount);

        // 更新用户的存款余额
        balances[msg.sender] += amount;
    }

    // 提取 Token
    function withdraw(uint256 amount) external {
        uint256 userBalance = balances[msg.sender];
        require(userBalance >= amount, "Insufficient balance");

        // 更新用户的存款余额
        balances[msg.sender] -= amount;

        // 转移 Token 到用户账户
        token.transfer(msg.sender, amount);
    }

    // 查询用户存入的 Token 数量
    function checkBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    // 新增的函数：tokensReceived
    function tokensReceived(address user, uint256 value) external {
        require(value > 0, "Value must be greater than 0");

        // 增加用户的存款
        balances[user] += value;
    }
}