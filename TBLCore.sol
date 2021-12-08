/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.1.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ICoreStackable {
    event SetStackableContractAddress(address stackableContractAddress);
    event Stack(address owner, uint256 balance, uint256 stackValue);
    event AddToStackable(address owner, uint blockNumber, uint256 value);
    event RemoveFromStackable(address owner, uint256 value);
    
    struct StackRow { 
      uint blockNumber;
      uint256 amount;
    }
    struct StackTable {
        uint256 balance;
        StackRow[] rows;
    }
    
    function linkStackableToken(address stackableContractAddress) external returns (bool);
    
    function transferToStask(uint256 amount) external returns (bool);
    
    function transferFromStack(uint256 amount) external returns (bool);
    
    function viewStack() external view returns (StackTable memory);
    
    function triggerStack() external returns (bool);
}

interface ITransfereWithLock {
    event CreateTransferWithLock(address sender, address recipient, uint256 amount, uint blockTimestamp, uint blockSeconds);
    event UnlockTransfers(address recipient, uint256 amount);
    
    struct TransferLockRow {
        uint blockTimestamp;
        uint blockSeconds;
        bool received;
        uint256 amount;
    }

    struct CreateTransferLockRow {
        address recipient;
        uint blockMinutes;
        uint256 amount;
    }
    
    struct TransferLockTable {
        TransferLockRow[] rows;
    }

    function transferWithLockDays(address recipient, uint256 amount, uint blockDays) external returns (bool);
    
    function transferWithLockHours(address recipient, uint256 amount, uint blockHours) external returns (bool);

    function transferWithLockMinutes(address recipient, uint256 amount, uint blockMinutes) external returns (bool);

    function massTransferWithLockMinutes(CreateTransferLockRow[] memory massLocks) external returns (bool);
        
    function receiveLockedTransfers() external returns (uint256);
    
    function viewUnreceivedTransfersWithLock() external view returns (TransferLockRow[] memory);
}

import 'https://github.com/AkredD/TBL-token/blob/main/common/ERC20WithComission.sol';
import 'https://github.com/AkredD/TBL-token/blob/main/common/Stackable.sol';

contract TBLCore is ERC20WithComission, ICoreStackable, ITransfereWithLock {
    uint256 constant NULL = 0;
   
    mapping (address => StackTable) private stackList;
    mapping (address => TransferLockTable) private lockedTransfers;
    

    IStackable public tblGame;
    
    
    constructor() ERC20WithComission("TinyBlastCore", "TBLC") {
        _mint(msg.sender, 2* 10**9 * 10**18);
    }

    function massTransferWithLockMinutes(CreateTransferLockRow[] memory massLocks) external override returns (bool) {
        for (uint i = 0; i < massLocks.length; ++i) {
            CreateTransferLockRow memory row = massLocks[i];
            transferWithLock(row.recipient, row.amount, row.blockMinutes * 60);
        }
        return true;
    }

    function transferWithLockDays(address recipient, uint256 amount, uint blockDays) external override returns (bool) {
        return transferWithLock(recipient, amount, blockDays * 24 * 60 * 60);
    }
    
    function transferWithLockHours(address recipient, uint256 amount, uint blockHours) external override returns (bool){
         return transferWithLock(recipient, amount, blockHours * 60 * 60);
    }

    function transferWithLockMinutes(address recipient, uint256 amount, uint blockMinutes) external override returns (bool){
         return transferWithLock(recipient, amount, blockMinutes * 60);
    }
    
    function transferWithLock(address recipient, uint256 amount, uint blockSeconds) private returns (bool) {
        address sender = _msgSender();
        uint256 balance = balanceOf(sender);
        require(balance >= amount, "TransferWithLockCore: transfer with lock amount exceeds balance");
        
        _balances[sender] = balance - amount;
        lockedTransfers[recipient].rows.push(TransferLockRow(block.timestamp, blockSeconds, false, amount));
        emit CreateTransferWithLock(sender, recipient, amount, block.timestamp, blockSeconds);
        
        return true;
    }
     
    function receiveLockedTransfers() external override returns (uint256) {
        address sender = _msgSender();
        uint currentTimestamp = block.timestamp;
        uint256 receivedAmount = 0;
        
        for (uint i = 0; i < lockedTransfers[sender].rows.length; i++) {
            TransferLockRow storage row = lockedTransfers[sender].rows[i];
            if (currentTimestamp - row.blockTimestamp > row.blockSeconds && !row.received) {
                row.received = true;
                receivedAmount += row.amount;
            }
        }
        
        require(receivedAmount > 0, "TransferWithLockCore: no transfers with lock can be unlocked");
        _balances[sender] = _balances[sender] + receivedAmount;
        emit UnlockTransfers(sender, receivedAmount);
        
        return 0;   
    }
     
    function viewUnreceivedTransfersWithLock() external view override returns (TransferLockRow[] memory) {
        address sender = _msgSender();
        
        uint unreceivedSize;
        for (uint i = 0; i < lockedTransfers[sender].rows.length; i++) {
            TransferLockRow memory row = lockedTransfers[sender].rows[i];
            if (!row.received) {
                unreceivedSize++;
            }
        }
        
        TransferLockRow[] memory unreceivedRows = new TransferLockRow[](unreceivedSize);

        for (uint i = 0; i < lockedTransfers[sender].rows.length; i++) {
            TransferLockRow memory row = lockedTransfers[sender].rows[i];
            if (!row.received) {
                unreceivedRows[--unreceivedSize] = row;
            }
        }
        
        return unreceivedRows;
    }
    

    function linkStackableToken(address stackableContractAddress) external override onlyOwner returns (bool) {
        tblGame = IStackable(stackableContractAddress);
        emit SetStackableContractAddress(stackableContractAddress);
        return true;
    }
    
    
    function transferToStask(uint256 amount) external override returns (bool) {
        address sender = _msgSender();
        uint256 balance = balanceOf(sender);
        require(balance >= amount, "StackableCore: transfer to stack amount exceeds balance");
        

        stackList[sender].rows.push(StackRow(block.number, amount));
        stackList[sender].balance += amount;

        
        emit AddToStackable(sender, block.number, amount);
        
        _balances[sender] = balance - amount;
        
        return true;
    }
    
    function transferFromStack(uint256 amount) external override returns (bool) {
        address sender = _msgSender();
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
        emit RemoveFromStackable(sender, amount);
        
        return true;
    }
    
    function viewStack() external view override returns (StackTable memory) {
        return stackList[_msgSender()];
    }
    
    function triggerStack() external override returns (bool) {
        uint currentBlock = block.number;
        uint256 stackedValue = 0;
        address sender = _msgSender();
        
        require(stackList[sender].balance > 0, "StackableCore: stack balance is 0");
        
        while(stackList[sender].rows.length != 0) {
            StackRow memory lastRow = stackList[sender].rows[stackList[sender].rows.length - 1];
            stackList[sender].rows.pop();
            
            // main stack logic (v0.02)
            stackedValue += (lastRow.amount * ((uint256(currentBlock - lastRow.blockNumber) * 1000000000) / uint256(6 * 60 * 24 * 365))) / 1000000000;
        }
        
        tblGame.stack(sender, stackedValue);
        emit Stack(_msgSender(), stackList[sender].balance, stackedValue);
        
        stackList[sender].rows.push(StackRow(currentBlock, stackList[sender].balance));
        return true;
    }

}
