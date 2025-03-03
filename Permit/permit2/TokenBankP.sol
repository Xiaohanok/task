// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MyToken} from "./Mytoken.sol";
import {IPermit2} from "../src/interfaces/IPermit2.sol";
import {ISignatureTransfer} from "../src/interfaces/ISignatureTransfer.sol";

contract TokenBank {
    MyToken public token;
    IPermit2 public myPermit;

    // 存款者的余额记录
    mapping(address => uint256) public balances;

    // 设置合约中的 ERC20 代币地址
    constructor(address tokenAddress, address Permit2address) {
        token = MyToken(tokenAddress);
        myPermit = IPermit2(Permit2address);
    }

    function getTransferDetails(address to, uint256 amount)
        private
        pure
        returns (ISignatureTransfer.SignatureTransferDetails memory)
    {
        return ISignatureTransfer.SignatureTransferDetails({to: to, requestedAmount: amount});
    }

    // 使用 permit 进行离线授权存款
    function depositWithPermit2(address from, uint256 amount, uint256 deadline, uint256 nonce, bytes calldata signature)
        external
    {
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(token), amount: amount}),
            nonce: nonce,
            deadline: deadline
        });
        ISignatureTransfer.SignatureTransferDetails memory transferDetails = getTransferDetails(address(this), amount);
        myPermit.permitTransferFrom(permit, transferDetails, from, signature);

        // 更新用户的存款余额
        balances[from] += amount;
    }

    // 提款函数
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // 更新余额并转账
        balances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }
}
