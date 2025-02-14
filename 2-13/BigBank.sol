pragma solidity ^0.8.0;

// 导入Bank合约
import "./Bank.sol";

// 创建BigBank合约，继承自Bank合约
contract BigBank is Bank {

    // 定义modifier，检查转账金额是否大于0.001 ether
    modifier onlyAboveMinimum() {
        if (msg.value <= 0.001 ether) {
            revert("Transfer must be greater than 0.001 ether");
        }
        _;
    }
    receive() external payable override onlyAboveMinimum {
        balances[msg.sender] += msg.value; // 增加该地址转账的ETH数量
        updateTopUsers(msg.sender); // 每次存款后更新前 3 名用户
    }
        //创建时使用admin地址作为管理者
        constructor(address adminAddress) {
        // 确保传入的地址不为空
        if (adminAddress == address(0)) {
            revert("Admin address cannot be the zero address");
        }

        // 将管理员地址(owner)转移给Admin合约地址
        owner = adminAddress;
    }
}