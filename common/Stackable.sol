// File @openzeppelin/contracts/utils/Context.sol@v4.1.0
/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.1.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStackable {
    function stack(address recipient, uint256 amount) external returns (bool);
    
    event Stack(address to, uint256 value);
}