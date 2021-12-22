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