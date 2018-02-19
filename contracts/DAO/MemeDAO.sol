pragma solidity ^0.4.18;
import "./MOMToken.sol";

contract ProposerInterface{
    function votePassed(uint256 _proposalNumber, uint256 _totalLockedTokens, bytes32 _proposalHash) public returns (bool);
    function executionSuccess(uint256 proposalNumber) public returns (bool);
}

// MemeDAO is the set as the owner of both the Proposer (voting) and MotherOfMemes (ERC721)
// Ownership of MOMToken represents ownership and voting rights in the DAO
// The DAO can (and will) vote to replace Proposer with an improved mechanism in the future
contract MemeDAO is MOMToken {
    event Execution(uint256 indexed proposalNumber, bytes32 indexed proposalHash);

    ProposerInterface proposer;

    /// CONSTRUCTOR
    function MemeDAO(uint256 _totalSupply, address _proposer) public {
        balances[msg.sender] = _totalSupply;
        totalSupply = _totalSupply;
        proposer = ProposerInterface(_proposer);
    }

    /// PUBLIC FUNCTIONS
    function() public payable {}

    function execute(uint256 proposalNumber, uint256 value, address destination, bytes data) public {
        bytes32 proposalHash = keccak256(destination, value, data);
        require(proposer.votePassed(proposalNumber, totalLockedTokens, proposalHash));
        require(destination.call.value(value)(data));
        require(proposer.executionSuccess(proposalNumber));
        Execution(proposalNumber, proposalHash);
    }

    // The DAO can vote to call this function through the proposer
    function changeProposer(address newProposer) public {
        require(msg.sender == address(this));
        proposer = ProposerInterface(newProposer);
    }
}
