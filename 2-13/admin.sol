pragma solidity ^0.8.0;

interface IBank {
    function withdraw(uint256 amount) external;
}

contract Admin {
    address public owner;

    // 设置合约的拥有者
    constructor() {
        owner = msg.sender;
    }

    // 修饰器：只有合约拥有者才能执行该函数
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    // 提款函数：从银行合约提取资金
    function adminWithdraw(IBank bank, uint256 amount) public onlyOwner {
        // 调用 IBank 合约中的 withdraw 函数
        bank.withdraw(amount);
    }
}
