// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MyToken} from "../src/ERC20P.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TokenBank {
    MyToken public token;

    // 存储每个账户的余额
    mapping(address => uint256) public balances;

    constructor(address _token) {
        token = MyToken(_token);
    }

    // 使用 permit 进行存款
    function permitDeposit(
        address owner,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // 调用 permit 方法以授权转移代币
        token.permit(owner, address(this), amount, deadline, v, r, s);
        
        // 转移代币到银行合约
        token.transferFrom(owner, address(this), amount);
        
        // 更新余额
        balances[owner] += amount;
    }

    // 查询余额
    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }
}