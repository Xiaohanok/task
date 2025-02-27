// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20Permit {
    // 合约的拥有者地址
    address public owner;

    // 初始化合约
    constructor(string memory name, string memory symbol) ERC20(name, symbol) ERC20Permit(name) {
        owner = msg.sender;  // 合约的创建者为拥有者
        _mint(msg.sender, 1e10 * 1e18); // 初始铸造代币
    }

    // mint 方法，允许拥有者铸造新的代币
    function mint(address to, uint256 amount) external {
        require(msg.sender == owner, "MyToken: Only owner can mint");
        _mint(to, amount);
    }
}