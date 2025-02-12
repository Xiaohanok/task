pragma solidity ^0.8.0;

contract Counter {
    uint public counter;

    constructor() {
        counter = 0;
    }

    function count() public {
        counter = counter + 1;
    }

    // 添加 get() 方法来获取 counter 的值
    function get() public view returns (uint) {
        return counter;
    }

    // 添加 add() 方法来增加指定的值
    function add(uint value) public {
        counter = counter + value;
    }
}
