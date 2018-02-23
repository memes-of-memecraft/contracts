pragma solidity ^0.4.18;
import "./MOMToken.sol";

contract ProposerInterface{
    function executionAllowed(uint256 _proposalNumber, bytes32 _proposalHash) public view returns (bool);
    function executionSuccess(uint256 _proposalNumber) public returns (bool);
}

// MemeDAO is the set as the owner of both the Proposer (voting) and MotherOfMemes (ERC721)
// Ownership of MOMToken represents ownership and voting rights in the DAO
// The DAO can will vote to replace Proposer with an improved mechanism in the future
contract MemeDAO is MOMToken {
    event Execution(uint256 indexed proposalNumber, bytes32 indexed proposalHash);

    address public proposerAddress;
    ProposerInterface proposer;

    function MemeDAO(uint256 _totalSupply, address _proposer) public {
        balances[msg.sender] = _totalSupply;
        totalSupply = _totalSupply;
        proposerAddress = _proposer;
        proposer = ProposerInterface(_proposer);
    }

    function() public payable {}

    function execute(uint256 _proposalNumber, uint256 _value, address _destination, bytes _data) public {
        bytes32 proposalHash = keccak256(_destination, _value, _data);
        require(proposer.executionAllowed(_proposalNumber, proposalHash));
        require(_destination.call.value(_value)(_data));
        require(proposer.executionSuccess(_proposalNumber));
        Execution(_proposalNumber, proposalHash);
    }

    function changeProposer(address _proposer) public {
        require(msg.sender == address(this));
        proposerAddress = _proposer;
        proposer = ProposerInterface(_proposer);
    }
}
