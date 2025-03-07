// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Bank {
    // 用户余额
    mapping(address => uint) public balanceOf;
    // 链表关系: current address => next address
    mapping(address => address) public NextAddress;
    // 链表大小
    address constant GUARD = address(0);
    
    event Deposit(address indexed user, uint amount);


    constructor() {
        NextAddress[GUARD] = GUARD;
    }

    
    function depositETH() public  payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balanceOf[msg.sender] += msg.value;

        updatePosition(msg.sender,balanceOf[msg.sender]);       

        emit Deposit(msg.sender, msg.value);
    }

    receive() external payable virtual {
            depositETH();
    }

    function withdraw(uint256 amount) public {
        require(amount <= balanceOf[msg.sender], "Insufficient  balance"); // 检查合约余额
        balanceOf[msg.sender] -= amount;
        if (balanceOf[msg.sender] == 0) {
            address pre = findPrevious(msg.sender);
            NextAddress[pre] = NextAddress[msg.sender];
            NextAddress[msg.sender] = GUARD;
        }
        else {
            updatePosition(msg.sender,balanceOf[msg.sender]);
        }

        payable(msg.sender).transfer(amount); // 提现到合约创建者地址
    }


    function insertNew(address user) internal {
        require(NextAddress[user] == address(0), "User already exists");
        
        address candidate = GUARD;
        while (NextAddress[candidate] != GUARD) {
            if (balanceOf[NextAddress[candidate]] < balanceOf[user]) {
                break;
            }
            candidate = NextAddress[candidate];
        }
        
        NextAddress[user] = NextAddress[candidate];
        NextAddress[candidate] = user;

    }

 
    function updatePosition(address user,uint256 balance) internal {
        if (balance != 0) {
        
            address prevUser = findPrevious(user);
            if (prevUser == address(0)) return;
            
            if (_verifyPosition(prevUser, balanceOf[user], NextAddress[user])) {
                return; // 位置正确，不需要移动
            }
            
            // 移除节点
            NextAddress[prevUser] = NextAddress[user];
            NextAddress[user] = address(0);
        }
        
        // 重新插入
        insertNew(user);
    }


    function findPrevious(address user) internal view returns (address) {
        address current = GUARD;
        while (NextAddress[current] != GUARD) {
            if (NextAddress[current] == user) {
                return current;
            }
            current = NextAddress[current];
        }
        return address(0);
    }


    function _verifyPosition(
        address prevUser, 
        uint256 value, 
        address nextUser
    ) internal view returns (bool) {
        return (prevUser == GUARD || balanceOf[prevUser] >= value) && 
               (nextUser == GUARD || value > balanceOf[nextUser]);
    }


function getTop10Users() external view returns (address[] memory, uint[] memory) {

    
    address current = NextAddress[GUARD];
    uint count = 0;

    while (current != GUARD && count < 10) {
        users[count] = current;
        balances[count] = balanceOf[current];
        current = NextAddress[current];
        count++;
    }

    assembly {
        mstore(users, count)  // 修正返回数组的长度
        mstore(balances, count)
    }

    return (users, balances);
}


}
