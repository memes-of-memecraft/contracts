pragma solidity ^0.4.18;
import "./SafeMath.sol";
import "./Ownable.sol";

contract DAOInterface {
    uint256 public totalSupply;
    uint256 public totalLockedTokens;
    function lockedBalance(address) public constant returns (uint256);
}

// Proposer is the DAO voting mechanism
// Proposer will be replaced with an improved contract in the future
// Owner will be set to MemeDAO.sol
contract Proposer is Ownable {
  using SafeMath for uint256;

  event Vote(address indexed voter, bool indexed vote, uint256 indexed voteAmount);
  event NewProposal(address indexed proposer, uint256 indexed proposalNumber);

  uint256 public proposalDuration;
  uint256 public voteThreshold;
  uint256 public winMargin;
  mapping(uint256 => Proposal) proposals;
  mapping(uint256 => bool) proposalExists;
  address public daoAddress;
  DAOInterface dao;

  struct Proposal {
     uint256 yesVotes;
     uint256 noVotes;
     uint256 startTime;
     bytes32 proposalHash;
     bool enacted;
     mapping(address => bool) alreadyVoted;
  }

  function Proposer() public {
      proposalDuration = 8;
      voteThreshold = 50;
      winMargin = 1;
  }

  function submitProposal(uint256 _proposalNumber, uint256 _value, address _destination, bytes _data) public {
      require(proposalExists[_proposalNumber] == false);
      require(dao.lockedBalance(msg.sender) > 0);
      bytes32 newProposalHash = keccak256(_destination, _value, _data);
      Proposal memory newProposal = Proposal(0, 0, now, newProposalHash, false);
      proposals[_proposalNumber] = newProposal;
      proposalExists[_proposalNumber] == true;
      NewProposal(msg.sender, _proposalNumber);
  }

  function vote(uint256 _proposalNumber, bool _yes) public {
      var prop = proposals[_proposalNumber];
      require(prop.alreadyVoted[msg.sender] == false);
      require(now <= prop.startTime.add(proposalDuration));
      uint256 voteCount = dao.lockedBalance(msg.sender);
      require(voteCount > 0);
      if (_yes) {
          prop.yesVotes = prop.yesVotes.add(voteCount);
      } else {
          prop.noVotes = prop.noVotes.add(voteCount);
      }
      Vote(msg.sender, _yes, voteCount);
      prop.alreadyVoted[msg.sender] = true;
  }

  function updateDAO(address _daoAddress) public onlyOwner {
      dao = DAOInterface(_daoAddress);
      daoAddress = _daoAddress;
  }

  function updateProposalDuration(uint256 _proposalDuration) public onlyOwner {
      proposalDuration = _proposalDuration;
  }

  function updateVoteThreshold(uint256 _voteThreshold) public onlyOwner {
      require(_voteThreshold > 0 && _voteThreshold <= 100);
      voteThreshold = _voteThreshold;
  }

  function updateWinMargin(uint256 _winMargin) public onlyOwner {
      require(_winMargin < dao.totalSupply());
      winMargin = _winMargin;
  }

  function executionSuccess(uint256 _proposalNumber) public onlyOwner returns (bool) {
     proposals[_proposalNumber].enacted = true;
     return true;
  }

  function executionAllowed(
      uint256 _proposalNumber,
      bytes32 _proposalHash
  )
      public
      view
      returns (bool)
  {
      require(proposals[_proposalNumber].enacted == false);
      uint256 _totalLockedTokens = dao.totalLockedTokens();
      require(_totalLockedTokens > 0);
      require(votePassed(_proposalNumber, _totalLockedTokens, _proposalHash));
      return true;
  }

  function viewProposal(uint256 _proposalNumber) public view returns (
      uint256 yesVotes,
      uint256 noVotes,
      uint256 startTime,
      bytes32 proposalHash,
      bool enacted
  )
  {
      yesVotes = proposals[_proposalNumber].yesVotes;
      noVotes = proposals[_proposalNumber].noVotes;
      startTime = proposals[_proposalNumber].startTime;
      proposalHash = proposals[_proposalNumber].proposalHash;
      enacted = proposals[_proposalNumber].enacted;
  }

  function votePassed(
      uint256 _proposalNumber,
      uint256 _totalLockedTokens,
      bytes32 _proposalHash
  )
      internal
      view
      returns (bool)
  {
      var prop = proposals[_proposalNumber];
      bool dataMatch = prop.proposalHash == _proposalHash;
      bool ended = now >= prop.startTime.add(proposalDuration);
      bool yes = prop.yesVotes > prop.noVotes.add(winMargin);
      uint256 totalVotes =  prop.yesVotes.add(prop.noVotes);
      bool minThreshold = totalVotes >= (_totalLockedTokens.mul(voteThreshold)).div(100);
      if (dataMatch && ended && yes && minThreshold) {
          return true;
      } else {
          return false;
      }
  }
}
