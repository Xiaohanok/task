// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSig {
    address[] public owners;
    uint public requiredConfirmations;
    mapping(address => bool) public isOwner;
    mapping(uint => Proposal) public proposals;
    uint public proposalCount;

    struct Proposal {
        address to;
        uint value;
        bytes data;
        uint confirmations;
        bool executed;
        mapping(address => bool) isConfirmed;
    }


    event ProposalCreated(uint proposalId, address to, uint value, bytes data);
    event ProposalConfirmed(uint proposalId, address owner);
    event ProposalExecuted(uint proposalId, address to, uint value, bytes data);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier notExecuted(uint proposalId) {
        require(!proposals[proposalId].executed, "Proposal already executed");
        _;
    }

    modifier onlyConfirmed(uint proposalId) {
        require(proposals[proposalId].confirmations >= requiredConfirmations, "Not enough confirmations");
        _;
    }

    constructor(address[] memory _owners ,uint _requiredConfirmations) {
        require(_owners.length >= 3, "At least 3 owners required");
        require(_requiredConfirmations <= _owners.length, "Required confirmations can't be more than owners");
        
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            isOwner[owner] = true;
            owners.push(owner);
        }
        
        requiredConfirmations = _requiredConfirmations;
    }

    // Create a proposal
    function createProposal(address _to, uint _value, bytes memory _data) public onlyOwner {
        uint proposalId = proposalCount++;
        Proposal storage proposal = proposals[proposalId];
        proposal.to = _to;
        proposal.value = _value;
        proposal.data = _data;
        proposal.confirmations = 0;
        proposal.executed = false;

        emit ProposalCreated(proposalId, _to, _value, _data);
    }

    // Confirm a proposal
    function confirmProposal(uint proposalId) public onlyOwner notExecuted(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.isConfirmed[msg.sender], "Already confirmed");

        proposal.isConfirmed[msg.sender] = true;
        proposal.confirmations++;

        emit ProposalConfirmed(proposalId, msg.sender);
    }

    // Execute a proposal if it has enough confirmations
    function executeProposal(uint proposalId) public onlyOwner notExecuted(proposalId) onlyConfirmed(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        
        proposal.executed = true;
        
        // Execute the transaction
        (bool success, ) = proposal.to.call{value: proposal.value}(proposal.data);
        require(success, "Transaction failed");

        emit ProposalExecuted(proposalId, proposal.to, proposal.value, proposal.data);
    }

    // Allow the contract to receive ETH
    receive() external payable {}


    // Get contract balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}