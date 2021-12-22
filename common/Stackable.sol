// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStackable {
    function stack(address recipient, uint256 amount) external returns (bool);
    
    event Stack(address to, uint256 value);
}