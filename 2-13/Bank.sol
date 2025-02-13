pragma solidity ^0.8.0;

contract Bank {
    // 映射，用于记录每个地址向合约转账的 ETH 数量
    mapping(address => uint256) public balances;

    // 合约创建者的地址
    address public owner;

    // 存储前 3 名用户的地址
    address[3] public topUsers;

    // 合约创建时初始化所有者
    constructor() {
        owner = msg.sender; // 合约创建者是部署合约的账户
    }

    // receive 函数会在合约收到 ETH 时触发
    receive() external payable {
        balances[msg.sender] += msg.value; // 增加该地址转账的ETH数量
        updateTopUsers(msg.sender); // 每次存款后更新前 3 名用户
    }

    // 获取某个地址转账的ETH数量
    function getBalanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    // 用于查询当前合约的ETH余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 只有合约的创建者可以调用的提现函数
    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "Only the owner can withdraw"); // 只有合约创建者可以提取
        require(amount <= address(this).balance, "Insufficient contract balance"); // 检查合约余额

        payable(owner).transfer(amount); // 提现到合约创建者地址
    }

    // 更新前 3 名用户的函数
    function updateTopUsers(address user) internal {
        uint256 userBalance = balances[user];

        // 遍历当前前 3 名用户
        for (uint256 i = 0; i < 3; i++) {
            if (userBalance > balances[topUsers[i]]) {
                for (uint256 j = 2; j > i; j--) {
                    topUsers[j] = topUsers[j - 1]; // 向后移动用户
                }
                topUsers[i] = user; // 将用户加入到当前的位置
                break;
            }
        }
    }

    // 读取 topUsers 数组的函数，返回前三名用户的地址
    function getTopUsers() public view returns (address[3] memory) {
        return topUsers;
    }
}