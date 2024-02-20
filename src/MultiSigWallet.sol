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
            require(!isOwner[_owners[i]], "owner repeats");
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
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
        isConfirmed[trxIndex][msg.sender] == true;
        transactions[trxIndex].numConfirmations++;

    }

    function revokeComfirmations(uint trxIndex) public OnlyOwner NotExecuted(trxIndex) {
        require(trxIndex < transactions.length && trxIndex > 0, "Incorrect index");
        require(isConfirmed[trxIndex][msg.sender], "Haven't comfired");
        isConfirmed[trxIndex][msg.sender] == false;
        transactions[trxIndex].numConfirmations--;
    }

    function executeTransaction(uint trxIndex) public OnlyOwner NotExecuted(trxIndex) {
        require(trxIndex < transactions.length && trxIndex > 0, "Incorrect index");
        require(transactions[trxIndex].numConfirmations >= numConfirmationsNeeded, "Not enough authorizations");
        transactions[trxIndex].executed = true;
        (bool success, ) = transactions[trxIndex].to.call{value: transactions[trxIndex].value}(
            transactions[trxIndex].data
        );
        if (success == false) revert TxexecuteFailed(trxIndex);
    }



}