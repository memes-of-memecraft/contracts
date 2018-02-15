pragma solidity ^0.4.18;
import "./SafeMath.sol";
import "./Ownable.sol";

contract DAOInterface {
    function lockedBalance(address) public constant returns (uint256);
}

// Proposer is the voting mechanism for the DAO
// This initial version will be replaced in the future
// Owner of contract will be set to MemeDAO.sol
contract Proposer is Ownable {
  using SafeMath for uint256;

  event Vote(address indexed voter, bool indexed vote, uint256 indexed voteAmount);
  event ProposedVote(address indexed proposer, uint256 indexed proposalNumber);

  uint256 public proposalDuration = 8 hours;
  uint256 public voteThreshold = 50;
  mapping(uint256 => Proposal) proposals;
  mapping(uint256 => bool) proposalExists;
  DAOInterface dao;

  struct Proposal {
     uint256 yesVotes;
     uint256 noVotes;
     uint256 startTime;
     bytes32 dataHash;
     bool enacted;
     mapping(address => bool) alreadyVoted;
  }


  function propose(uint256 _proposalNumber, bytes32 _dataHash) public {
      require(proposalExists[_proposalNumber] == false);
      require(dao.lockedBalance(msg.sender) > 0);
      Proposal memory newProposal = Proposal(0, 0, now, _dataHash, false);
      proposals[_proposalNumber] = newProposal;
      proposalExists[_proposalNumber] == true;
      ProposedVote(msg.sender, _proposalNumber);
  }

  function vote(uint256 _proposalNumber, bool _voteType) public {
      var prop = proposals[_proposalNumber];
      require(prop.alreadyVoted[msg.sender] == false);
      require(now <= prop.startTime.add(proposalDuration));
      uint256 voteCount = dao.lockedBalance(msg.sender);
      require(voteCount > 0);
      if (_voteType) {
          prop.yesVotes = prop.yesVotes.add(voteCount);
      } else {
          prop.noVotes = prop.noVotes.add(voteCount);
      }
      Vote(msg.sender, _voteType, voteCount);
      prop.alreadyVoted[msg.sender] = true;
  }

  function executionSuccess(uint256 _proposalNumber) public onlyOwner returns (bool) {
     var prop = proposals[_proposalNumber];
     prop.enacted = true;
     return true;
  }

  function updateDAO(address newAddress) public onlyOwner {
      dao = DAOInterface(newAddress);
  }

  function updateProposalDuration(uint256 newDuration) public onlyOwner {
      proposalDuration = newDuration;
  }

  function updateVoteThreshold(uint256 newThreshold) public onlyOwner {
      voteThreshold = newThreshold;
  }

  function viewProposal(uint256 _proposalNumber) public view returns (
      uint256 yesVotes,
      uint256 noVotes,
      uint256 startTime,
      bytes32 dataHash,
      bool enacted
  )
  {
      yesVotes = proposals[_proposalNumber].yesVotes;
      noVotes = proposals[_proposalNumber].noVotes;
      startTime = proposals[_proposalNumber].startTime;
      dataHash = proposals[_proposalNumber].dataHash;
      enacted = proposals[_proposalNumber].enacted;
  }

  function votePassed(uint256 _proposalNumber, uint256 _totalLockedTokens, bytes32 _dataHash) public view returns (bool) {
      var prop = proposals[_proposalNumber];
      bool dataMatch = prop.dataHash == _dataHash;
      bool ended = now >= prop.startTime.add(proposalDuration);
      bool yes = prop.yesVotes >= prop.noVotes;
      uint256 totalVotes =  prop.yesVotes.add(prop.noVotes);
      bool minThreshold = totalVotes >= (_totalLockedTokens.mul(voteThreshold)).div(100);
      if (dataMatch && ended && yes && minThreshold) {
          return true;
      } else {
          return false;
      }
  }
}
