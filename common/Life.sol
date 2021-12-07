/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.1.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ILife {
    event SetLifeCompanies(LifeRow[] lifeCompanies);
    
    struct LifeRow {
        address lifeAddress;
        uint part;
    }
    
    function setLifeCompanies(LifeRow[] memory lifeCompanies) external;

    function getLifeCompamies() external view returns (LifeRow[] memory);
}