pragma solidity ^0.4.18;
import "./ERC721Token.sol";
import "./Ownable.sol";
import "./ByteUtils.sol";
import "./ECRecovery.sol";


// Owner will be set to the DAO
contract MotherOfMemes is ERC721Token, Ownable {
    using SafeMath for uint256;

    /// CONSTANTS
    string public constant name = "Mother of Memes";
    string public constant symbol = "MEMES";

    /// STORAGE
    address userAdmin;                            // user admin maintains whitelist and is elected by the DAO
    uint256 tokenQueue;                           // issued memes that have not been mined
    uint256 hashPeriod = 2000;                    // whitelisted accounts can play each other once per period
    uint256 bitShiftAmount = 255;                 // probability of winning = 0.5**(256 - bitShiftAmount)
    mapping(address => bool) userList;            // whitelist for sybil resistance
    mapping(uint256 => bytes32) ruleSets;         // hashed "official" rulesets

    /// MODIFIERS
    modifier onlyUserAdmin() {
        require(msg.sender == userAdmin);
        _;
    }

    /// EXTERNAL FUNCTIONS
    function mine(address _winner, address _loser, bytes _sigs) external {
        require(userList[_winner] && userList[_loser]);
        require(verifyWin(_sigs));
        require(checkSignatures(_winner, _loser, _sigs));
        assignToken(_winner);
    }

    function changeHashPeriod(uint256 _hashPeriod) external onlyOwner {
        require(_hashPeriod > 0 && _hashPeriod < block.number);
        hashPeriod = _hashPeriod;
    }

    function changeBitShiftAmount(uint256 _bitShiftAmount) external onlyOwner {
        require(_bitShiftAmount > 0 && _bitShiftAmount <= 256);
        bitShiftAmount = _bitShiftAmount;
    }

    function issueTokens(uint256 _amount) external onlyOwner {
        require(_amount != 0);
        tokenQueue = tokenQueue.add(_amount);
    }

    function changeUserlistAdmin(address _userAdmin) external onlyOwner {
        require(_userAdmin != address(this) && _userAdmin != address(0));
        userAdmin = _userAdmin;
    }

    function updateUserlist(address _user, bool _listed) external onlyUserAdmin {
        require(userList[_user] != _listed);
        userList[_user] = _listed;
    }

    function changeRuleSet(uint256 ruleSetNumber, bytes32 ruleSetHash) external onlyOwner {
        ruleSets[ruleSetNumber] = ruleSetHash;
    }

    function getRuleSet(uint256 ruleNumber) external view returns (bytes32) {
       return ruleSets[ruleNumber];
    }

    /// PUBLIC FUNCTIONS
    function getPeriodicHash() public view returns (bytes32 winningHash) {
        winningHash = block.blockhash(block.number % hashPeriod);
    }

    /// INTERNAL FUNCTIONS
    function verifyWin(bytes sigs) internal view returns (bool) {
        bytes32 sigHash = keccak256(sigs);
        uint256 sigInt = uint256(sigHash);
        uint256 sigShifted = sigInt >> bitShiftAmount;
        return sigShifted == 0;
    }

    function checkSignatures(
        address winner,
        address loser,
        bytes sigs
    )
        internal
        view
        returns (bool)
    {
        require(sigs.length == 130);
        bytes32 periodicHash = getPeriodicHash();
        bytes memory sig1 = ByteUtils.slice(sigs, 0, 65);                           // digital signature submitted by winner
        bytes memory sig2 = ByteUtils.slice(sigs, 65, 65);                          // digital signature submitted by loser
        bytes32 winnerHash = keccak256(sig2);                                       // hash of losers digital signature
        bytes32 loserHash = keccak256(winner, loser, periodicHash);                 // hash of winner address, loser address
        bool checkWinnerSig = winner == ECRecovery.recover(winnerHash, sig1);       // check that winner signed a hash of losers signature
        bool checkLoserSig = loser == ECRecovery.recover(loserHash, sig2);          // check that loser signed a hash of the game, winning address, losing address
        return checkWinnerSig && checkLoserSig;
    }

    function assignToken(address _recipient) internal {
        require(tokenQueue > 0);
        tokenQueue = tokenQueue.sub(1);
        uint256 tokenID = totalSupply();
        _mint(_recipient, tokenID);
    }
}
