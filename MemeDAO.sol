pragma solidity ^0.4.19;
import "./MOMToken.sol";

contract MemeDAO is MOMToken {
    using SafeMath for uint256;

    event Vote(address indexed voter, bool indexed vote, uint256 indexed voteAmount);
    event ProposedVote(address indexed proposer, uint256 indexed proposalNumber);
    event EnactedProposal(uint256 indexed proposalNumber);

    uint256 proposalDuration = 3 days;    // duration of a bote
    //uint256 minPercentage = 20;           // min percentage of locked tokens needed to pass a vote (still requires majority)
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
        proposals[_proposalNumber] = Proposal(0, 0, now, _ethValue, _data, _destination, false);
        proposalExists[_proposalNumber] == true;
        ProposedVote(msg.sender, _proposalNumber);
    }

    function vote(uint256 _proposalNumber, bool _voteType) public onlyTokenHolder {
        var voteProposal = proposals[_proposalNumber];
        require(voteProposal.alreadyVoted[msg.sender] == false);
        require(now <= voteProposal.startTime.add(proposalDuration));
        if (_voteType) {
            voteProposal.yesVotes.add(lockedTokens[msg.sender]);
        } else {
            voteProposal.noVotes.add(lockedTokens[msg.sender]);
        }
        Vote(msg.sender, _voteType, lockedTokens[msg.sender]);
        voteProposal.alreadyVoted[msg.sender] = true;
    }

    function enactProposal(uint256 _proposalNumber) public onlyTokenHolder {
        require(votePassed(_proposalNumber));
        var voteProposal = proposals[_proposalNumber];
        voteProposal.enacted = true;
        if (voteProposal.destination.call.value(voteProposal.ethValue)(voteProposal.data))
                EnactedProposal(_proposalNumber);
        else {
            voteProposal.enacted = false;
          }
    }

    function votePassed(uint256 _proposalNumber) internal view returns (bool) {
        var voteProposal = proposals[_proposalNumber];
        bool ended = now >= voteProposal.startTime.add(proposalDuration);
        bool yes = voteProposal.yesVotes >= voteProposal.noVotes;
        if (ended && yes) {
            return true;
        } else {
            return false;
        }
    }
}
