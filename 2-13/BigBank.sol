pragma solidity ^0.8.0;

// 导入Bank合约
import "./Bank.sol";

// 创建BigBank合约，继承自Bank合约
contract BigBank is Bank {

    address public owner; // 管理员地址

    // 定义modifier，检查转账金额是否大于0.001 ether
    modifier onlyAboveMinimum() {
        if (msg.value <= 0.001 ether) {
            revert("Transfer must be greater than 0.001 ether");
        }
        _;
    }

    // 只有当前管理员才可以调用的修饰符
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // receive函数，用于接收ETH并更新余额
    receive() external payable override onlyAboveMinimum {
        balances[msg.sender] += msg.value; // 增加该地址转账的ETH数量
        updateTopUsers(msg.sender); // 每次存款后更新前 3 名用户
    }

    // 默认将部署者设置为管理员
    constructor() {
        owner = msg.sender; // 将合约创建者设置为管理员
    }

    // 修改管理员地址的函数
    function changeOwner(address newOwner) public onlyOwner {
        // 确保新地址不为空
        require(newOwner != address(0), "New owner address cannot be the zero address");
        
        // 更新管理员地址
        owner = newOwner;
    }
}
