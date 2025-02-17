// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 定义一个接口，确保目标合约有 tokensReceived 方法
interface ITokenReceiver {
    function tokensReceived(address from, uint256 value) external;
}

contract BaseERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) balances; 
    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * (10**decimals);
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        require(_to != address(0), "Receiver should not be zero");
        
        balances[msg.sender] -= _value; 
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");
        require(_to != address(0), "Invalid address");

        balances[_from] -= _value;
        balances[_to] += _value;

        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);  
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid address");
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    // 新增带 hook 的转账函数
    function transferWithCallback(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        require(_to != address(0), "Receiver should not be zero");
        
        balances[msg.sender] -= _value; 
        balances[_to] += _value;

        // 如果目标地址是合约地址且实现了 ITokenReceiver 接口，则调用 tokensReceived
        if (isContract(_to)) {
            ITokenReceiver(_to).tokensReceived(msg.sender, _value);
        }

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    // 判断地址是否为合约地址
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}