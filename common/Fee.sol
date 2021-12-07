/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.1.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IFee {
    event SetLiquidityFee(uint liquidityFee);
    event SetBurnFee(uint burnFee);
    event SetLifeFee(uint lifeFee);
    
    function getAllFee() external view returns (uint);
    
    function setLiquidityFee(uint _liquidityFee) external;
    
    function setBurnFee(uint _burnFee) external;
    
    function setLifeFee(uint _lifeFee) external;
}

import '../util/Ownable.sol';

abstract contract Fee is Ownable, IFee {
    uint public liquidityFee = 0; 
    uint public burnFee = 5 * 10**3; 
    uint public lifeFee = 0; 
    
    function getAllFee() external override view returns (uint) {
        return liquidityFee + burnFee + lifeFee;
    }
    
    function setLiquidityFee(uint _liquidityFee) external onlyOwner override {
        require(checkLimitFee(_liquidityFee, burnFee, lifeFee), "Expire fee limit");
        liquidityFee = _liquidityFee;
        emit SetLiquidityFee(_liquidityFee);
    }
    
    function setBurnFee(uint _burnFee) external onlyOwner override {
        require(checkLimitFee(liquidityFee, _burnFee, lifeFee), "Expire fee limit");
        burnFee = _burnFee;
        emit SetBurnFee(_burnFee);
    }
    
    function setLifeFee(uint _lifeFee) external onlyOwner override {
        require(checkLimitFee(liquidityFee, burnFee, _lifeFee), "Expire fee limit");
        lifeFee = _lifeFee;
        emit SetLifeFee(_lifeFee);
    }
    
    function checkLimitFee(uint _liquidityFee, uint _burnFee, uint _lifeFee) private pure returns (bool) {
        return _liquidityFee + _burnFee + _lifeFee <= 5 * 10**3;
    }
}