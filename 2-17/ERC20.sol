// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        // 设置 token 的名称、符号、小数位、总量
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * (10**decimals);
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // 返回指定地址的 token 余额
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // 转账函数，检查余额并执行转账
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        require(_to != address(0), "Receiver should not be zero");
        
        balances[msg.sender] -= _value; 
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // 执行从某个地址到另一个地址的转账
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
        // 允许某个地址使用 sender 的 token
        require(_spender != address(0), "Invalid address");
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true; 
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // 查询某个地址可以从另一个地址转账的剩余代币数量
        return allowances[_owner][_spender];
    }
}