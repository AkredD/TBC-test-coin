// SPDX-License-Identifier: MIT


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

pragma solidity ^0.8.4;

import './common/ERC20WithComission.sol';
import './common/StackCore.sol';

contract TBLCore is ERC20WithComission, StackCore, ITransfereWithLock {
    uint256 constant NULL = 0;
   
    mapping (address => TransferLockTable) private lockedTransfers;
    
    
    constructor() ERC20WithComission("TinyBlastCore", "TBLC") {
        _mint(msg.sender, 2 * 10**9 * 10**18);
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
    
    
    
    function transferToStask(uint256 amount) external  {
        address sender = _msgSender();
        uint256 balance = balanceOf(sender);
        require(balance >= amount, "StackableCore: transfer to stack amount exceeds balance");
        
        //StackCore function
        addToStack(amount, sender);
        
        _balances[sender] -= amount;
    }
    
    function transferFromStack(uint256 amount) external {
        address sender = _msgSender();
        
        //StackCore function
        removeFromStack(amount, sender);

        _balances[sender]+= amount;
    }
}
