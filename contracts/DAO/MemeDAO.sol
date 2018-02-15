pragma solidity ^0.4.18;
import "./MOMToken.sol";

contract MemeDAO is MOMToken {
    using SafeMath for uint256;

    event Vote(address indexed voter, bool indexed vote, uint256 indexed voteAmount);
    event ProposedVote(address indexed proposer, uint256 indexed proposalNumber);
    event EnactedProposal(uint256 indexed proposalNumber);

    uint256 public proposalDuration = 8 hours;
    uint256 public voteThreshold = 50;                   // min percentage of totalLockedTokens that must participate
    mapping(uint256 => Proposal) proposals;
    mapping(uint256 => bool) proposalExists;

    struct Proposal {
       uint256 yesVotes;
       uint256 noVotes;
       uint256 startTime;
       uint256 ethValue;
       bytes data;
       address destination;
       bool enacted;
       mapping(address => bool) alreadyVoted;
    }

    modifier onlyTokenHolder() {
        require(lockedTokens[msg.sender] >= 1);
        _;
    }

    /// CONSTRUCTOR
    function MemeDAO(uint256 _totalSupply) public {
        balances[msg.sender] = _totalSupply;
        totalSupply = _totalSupply;
    }

    /// PUBLIC FUNCTIONS
    function() public payable {}

    function propose(
        uint256 _proposalNumber,
        uint256 _ethValue,
        bytes _data,
        address _destination
    )
        public
        onlyTokenHolder
    {
        require(proposalExists[_proposalNumber] == false);
        Proposal memory newProposal = Proposal(0, 0, now, _ethValue, _data, _destination, false);
        proposals[_proposalNumber] = newProposal;
        proposalExists[_proposalNumber] == true;
        ProposedVote(msg.sender, _proposalNumber);
    }

    function vote(uint256 _proposalNumber, bool _voteType) public onlyTokenHolder {
        var prop = proposals[_proposalNumber];
        require(prop.alreadyVoted[msg.sender] == false);
        require(now <= prop.startTime.add(proposalDuration));
        if (_voteType) {
            prop.yesVotes = prop.yesVotes.add(lockedTokens[msg.sender]);
        } else {
            prop.noVotes = prop.noVotes.add(lockedTokens[msg.sender]);
        }
        Vote(msg.sender, _voteType, lockedTokens[msg.sender]);
        prop.alreadyVoted[msg.sender] = true;
    }

    function enactProposal(uint256 _proposalNumber) public onlyTokenHolder {
        require(votePassed(_proposalNumber));
        var prop = proposals[_proposalNumber];
        require(proposals[_proposalNumber].enacted == false);
        prop.enacted = true;
        if (prop.destination.call.value(prop.ethValue)(prop.data))
                EnactedProposal(_proposalNumber);
        else {
            prop.enacted = false;
          }
    }

    function viewProposal(uint256 _proposalNumber) public view returns (
        uint256 yesVotes,
        uint256 noVotes,
        uint256 startTime,
        uint256 ethValue,
        bytes data,
        address destination,
        bool enacted
    )
    {
        yesVotes = proposals[_proposalNumber].yesVotes;
        noVotes = proposals[_proposalNumber].noVotes;
        startTime = proposals[_proposalNumber].startTime;
        ethValue = proposals[_proposalNumber].ethValue;
        data = proposals[_proposalNumber].data;
        destination = proposals[_proposalNumber].destination;
        enacted = proposals[_proposalNumber].enacted;
    }

    /// INTERNAL FUNCTIONS
    function votePassed(uint256 _proposalNumber) internal view returns (bool) {
        var prop = proposals[_proposalNumber];
        bool ended = now >= prop.startTime.add(proposalDuration);
        bool yes = prop.yesVotes >= prop.noVotes;
        uint256 totalVotes =  prop.yesVotes.add(prop.noVotes);
        bool minThreshold = totalVotes >= (totalLockedTokens.mul(voteThreshold)).div(100);
        if (ended && yes && minThreshold) {
            return true;
        } else {
            return false;
        }
    }
}
