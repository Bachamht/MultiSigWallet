// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    
    address [] public owners;
    uint numConfirmationsNeeded;
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
    }
    
    mapping(uint => mapping(address => bool)) isConfirmed;
    mapping(address => bool) isOwner;
    Transaction [] public transactions;

    error NotOwner(address msgSender);
    error HaveExecuted(uint trxIndex);
    error TxexecuteFailed(uint trxIndex);
    modifier OnlyOwner() {
        if (isOwner[msg.sender] == false) revert NotOwner(msg.sender);
        _;
    }

    modifier NotExecuted(uint trxIndex) {
        if (transactions[trxIndex].executed == true) revert HaveExecuted(trxIndex);
        _;
    }

    constructor (address [] memory _owners, uint _numConfirmationsNeeded ) {

        require(_owners.length > 0, "need owners");
        require(_numConfirmationsNeeded > 0 && _numConfirmationsNeeded < _owners.length, "Incorrect number of verifications");
        for(uint i = 0; i < _owners.length; i++) {
            address owner_ = _owners[i];
            require(!isOwner[owner_], "owner repeats");
            isOwner[owner_] = true;
            owners.push(owner_);
        }
        numConfirmationsNeeded = _numConfirmationsNeeded;
        
    }


    function submitTransaction(address _to, uint _value, bytes memory _data) public OnlyOwner {

        uint trxIndex = transactions.length;
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );  
    }

    function confirmTransaction(uint trxIndex) public OnlyOwner NotExecuted(trxIndex){

        require(trxIndex < transactions.length && trxIndex > 0, "Incorrect index");
        require(!isConfirmed[trxIndex][msg.sender], "Have comfired");
        Transaction storage trx = transactions[trxIndex];
        isConfirmed[trxIndex][msg.sender] == true;
        trx.numConfirmations++;

    }

    function revokeComfirmations(uint trxIndex) public OnlyOwner NotExecuted(trxIndex) {

        require(trxIndex < transactions.length && trxIndex > 0, "Incorrect index");
        require(isConfirmed[trxIndex][msg.sender], "Haven't comfired");
        Transaction storage trx = transactions[trxIndex];
        isConfirmed[trxIndex][msg.sender] == false;
        trx.numConfirmations--;

    }

    function executeTransaction(uint trxIndex) public OnlyOwner NotExecuted(trxIndex) {
        Transaction storage trx = transactions[trxIndex];
        require(trxIndex < transactions.length && trxIndex > 0, "Incorrect index");
        require(trx.numConfirmations >= numConfirmationsNeeded, "Not enough authorizations");
        trx.executed = true;
        (bool success, ) = trx.to.call{value: transactions[trxIndex].value}(
            trx.data
        );
        if (success == false) revert TxexecuteFailed(trxIndex);

    }



}