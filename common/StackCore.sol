// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../util/Ownable.sol';
import './Stackable.sol';

abstract contract StackCore is Ownable {
    event SetStackableContractAddress(address stackableContractAddress);
    event Stack(address owner, uint256 balance, uint256 stackValue);
    event AddToStackable(address owner, uint blockNumber, uint256 value);
    event RemoveFromStackable(address owner, uint256 value);
    event FixWeekPool(uint startWeekTimestamp, uint endWeekTimestamp, uint256 totalLockedSupply);


    struct StackRow { 
      uint timestamp;
      uint256 amount;
    }
    struct StackTable {
        uint256 balance;
        StackRow[] rows;
    }


    uint public immutable zeroWeek;
    uint public immutable startWeekStackSupply;

    mapping (uint => uint256) public stackWeekMap;
    uint256 public currentStackValue;
    mapping (address => StackTable) private stackList;
    

    IStackable public tblGame;


    constructor() {
        zeroWeek = getCurrentEpochWeek();
        startWeekStackSupply = 6923 * 10**18;
    }

    function getSupplyByWeek(uint week) private view returns (uint) {
        uint yearNumber = (week - zeroWeek) / 52;
        if (yearNumber > 4) {
            yearNumber = 4;
        }

        return startWeekStackSupply / (2 ** (yearNumber));
    }

    function linkStackableToken(address stackableContractAddress) external onlyOwner {
        tblGame = IStackable(stackableContractAddress);
        emit SetStackableContractAddress(stackableContractAddress);
    }


    function getCurrentEpochWeek() public view returns (uint) {
        return fromEpochSecondToEpochWeek(block.timestamp);
    }

    function fromEpochSecondToEpochWeek(uint timestamp) private pure returns (uint) {
        return timestamp / getEpochPeriod();
    }

    function fromEpochWeekToTimestamp(uint epochWeek) private pure returns (uint) {
        return epochWeek * getEpochPeriod();
    }

    function getEpochPeriod() private pure returns (uint) {
        //return 60 * 60 * 24 * 7; target week
        return 60 * 60; // hour
    }

    function addToStack(uint256 amount, address sender) internal {
        tryToFillStackWeekMap();

        stackList[sender].rows.push(StackRow(block.timestamp, amount));
        currentStackValue += amount;

        emit AddToStackable(sender, block.number, amount);
    }

    function removeFromStack(uint256 amount, address sender) internal {
        tryToFillStackWeekMap();

        uint256 stackBalance = stackList[sender].balance;
        require(stackBalance >= amount, "StackableCore: transfer from stack amount exceeds stack balance");

        uint256 leftAmount = amount;
        while (leftAmount != 0) {
            StackRow memory lastRow = stackList[sender].rows[stackList[sender].rows.length - 1];
            stackList[sender].rows.pop();
            if (lastRow.amount > leftAmount) {
                lastRow.amount -= leftAmount;
                leftAmount = 0;
                stackList[sender].rows.push(lastRow);
            } else {
                leftAmount -= lastRow.amount;
            }
        }

        stackList[sender].balance -= amount;
        currentStackValue -= amount;

        emit RemoveFromStackable(sender, amount);
    }


    function tryToFillStackWeekMap() internal {
        uint currentWeek = getCurrentEpochWeek();

        uint weekIndex = currentWeek - 1;
        while(currentWeek > zeroWeek && stackWeekMap[currentWeek] == 0){
            emit FixWeekPool(fromEpochWeekToTimestamp(weekIndex), fromEpochWeekToTimestamp(weekIndex + 1), currentStackValue);
            stackWeekMap[weekIndex--] = currentStackValue;
        }
    }

    
    function triggerStack() external {
        tryToFillStackWeekMap();
        address sender = _msgSender();
        
        require(stackList[sender].balance > 0, "StackableCore: stack balance is 0");
        
        uint256 stackResult = evaluateTriggerStack(sender);

        while(stackList[sender].rows.length != 0) {
            stackList[sender].rows.pop(); 
        }
        
        tblGame.stack(sender, stackResult);
        emit Stack(_msgSender(), stackList[sender].balance, stackResult);
        
        stackList[sender].rows.push(StackRow(block.timestamp, stackList[sender].balance));
    }

    function evaluateTriggerStack(address sender) public view returns (uint256) {
        uint256 supplyStackValue;
        uint256 stackResult;

        uint currentEpochWeek = getCurrentEpochWeek();

        for (uint i = 0; i < stackList[sender].rows.length; i++) {
            StackRow memory row = stackList[sender].rows[i];
            uint rowEpochWeek = fromEpochSecondToEpochWeek(row.timestamp) + 1;
            supplyStackValue += row.amount;

            // if last stack - check until current week
            if (i + 1 == stackList[sender].rows.length) {
                for (uint j = rowEpochWeek; j < currentEpochWeek; ++j) {
                    stackResult += (getSupplyByWeek(rowEpochWeek) * ((supplyStackValue * 10**9) / stackWeekMap[j])) / 10**9;
                }
            // if else - check until next addToStack week
            } else {
                uint nextRowEpochWeek = fromEpochSecondToEpochWeek(stackList[sender].rows[i + 1].timestamp) + 1;
                for (uint j = rowEpochWeek; j < nextRowEpochWeek && j < currentEpochWeek; ++j){
                    stackResult += (getSupplyByWeek(rowEpochWeek) * ((supplyStackValue * 10**9) / stackWeekMap[j])) / 10**9;
                }
            }
        }

        return stackResult;
    }

    function viewStack() external view returns (StackTable memory) {
        return stackList[_msgSender()];
    }

}