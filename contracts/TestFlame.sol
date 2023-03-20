// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Flame.sol";

contract TestFlameToken is FlameToken {
    function lock(address to, uint8 ltype, uint256 amount) public {
        _lock(to,ltype,amount);
    }

    constructor(){
    }
}