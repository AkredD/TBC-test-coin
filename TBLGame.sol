/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.1.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './util/Ownable.sol';
import './common/ERC20WithComission.sol';
import './common/Stackable.sol';

contract TBLGame is ERC20WithComission, IStackable {
    address public _stackAddressOwner = 0x0813d4a158d06784FDB48323344896B2B1aa0F85;
    LifeRow[] private lifeCompanies;

    constructor() ERC20WithComission("TinyBlastGame", "TBLG") {
        _mint(msg.sender, 5 * 10**5 * 10**18);
    }
    
    //Test only function
    function setStackAddress(address newStackAddress) public returns (bool) {
        _stackAddressOwner = newStackAddress;
        return true;
    }
    
    function stack(address recipient, uint256 amount)
        public
        override
        returns (bool) {
        require(_msgSender() == _stackAddressOwner,
        string(
            abi.encodePacked(
                "Only contract can stack. Not ",
                string(
                    abi.encodePacked(_msgSender())
                    )
                )
            )
        );
        _mint(recipient, amount);
        emit Stack(recipient, amount);
        return true;
    }

    function getOwner() external view returns (address) {
        return owner();
    }
}
