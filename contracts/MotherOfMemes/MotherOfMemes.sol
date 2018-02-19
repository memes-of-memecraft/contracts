pragma solidity ^0.4.18;
import "./ERC721Token.sol";
import "./Ownable.sol";
import "./ByteUtils.sol";
import "./ECRecovery.sol";


contract Memes is ERC721Token {
    string public constant name = "Mother of Memes";
    string public constant symbol = "MEMES";
}

// Owner will be set to the DAO
contract MotherOfMemes is Memes, Ownable {
    using SafeMath for uint256;

    address userAdmin;
    uint256 memeQueue;
    uint256 hashPeriod = 2000;
    mapping(address => bool) userList;          // whitelist for sybil resistance
    mapping(uint32 => bytes32) ruleSets;        // hashed "official" rulesets

    modifier onlyUserAdmin() {
        require(msg.sender == userAdmin);
        _;
    }

    /// EXTERNAL FUNCTIONS
    function changeUserlistAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(this) && newAdmin != address(0));
        userAdmin = newAdmin;
    }

    function addUser(address user) external onlyUserAdmin {
        require(userList[user] == false);
        userList[user] = true;
    }

    function removeUser(address user) external onlyUserAdmin {
        require(userList[user] == true);
        userList[user] = false;
    }

    function changeRuleSet(uint32 ruleSetNumber, bytes32 ruleSetHash) external onlyOwner {
        ruleSets[ruleSetNumber] = ruleSetHash;

    }

    function getRuleSet(uint32 ruleNumber) external view returns (bytes32) {
       return ruleSets[ruleNumber];
    }

    function changeHashPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod > 0 && newPeriod < block.number);
        hashPeriod = newPeriod;
    }

    function issueMemes(uint256 _amount) external onlyOwner {
        require(_amount != 0);
        memeQueue = memeQueue.add(_amount);
    }

    function mine(address _winner, address _loser, bytes _sigs) external {
        require(userList[_winner] == true && userList[_loser] == true);
        bytes32 _periodicHash = getPeriodicHash();
        verifyWin(_periodicHash, _sigs);
        require(checkSignatures(_winner, _loser, _periodicHash, _sigs));
        assignMeme(_winner);
    }

    /// PUBLIC FUNCTIONS
    function getPeriodicHash() public view returns (bytes32 winningHash) {
        winningHash = block.blockhash(block.number % hashPeriod);
    }

    /// INTERNAL FUNCTIONS
    function verifyWin(
        bytes32 periodicHash,
        bytes sigs
    )
        internal
        pure
        returns (bool)
    {
        bytes1 winningNumbers = periodicHash[0];
        bytes1 userNumbers = sigs[0];
        uint8 winningInt = uint8(winningNumbers);
        uint8 winShifted = winningInt / 2**7;
        uint8 userInt = uint8(userNumbers);
        uint8 userShifted = userInt / 2**7;
        return userShifted == winShifted;
    }

    function checkSignatures(
        address winner,
        address loser,
        bytes32 periodicHash,
        bytes sigs
    )
        internal
        pure
        returns (bool)
    {
        require(sigs.length % 65 == 0 && sigs.length <= 130);
        bytes memory sig1 = ByteUtils.slice(sigs, 0, 65);                           // digital signature submitted by winner
        bytes memory sig2 = ByteUtils.slice(sigs, 65, 65);                          // digital signature submitted by loser
        bytes32 winnerHash = keccak256(sig2);                                      // hash of losers digital signature
        bytes32 loserHash = keccak256(winner, loser, periodicHash);                              // hash of winner address, loser address
        bool checkWinnerSig = winner == ECRecovery.recover(winnerHash, sig1);      // check that winner signed a hash of losers signature
        bool checkLoserSig = loser == ECRecovery.recover(loserHash, sig2);         // check that loser signed a hash of the game, winning address, losing address
        return checkWinnerSig && checkLoserSig;
    }

    function assignMeme(address _recipient) internal {
        require(memeQueue > 0);
        memeQueue = memeQueue.sub(1);
        uint256 tokenID = totalTokens;
        addToken(_recipient, tokenID);
    }

}
