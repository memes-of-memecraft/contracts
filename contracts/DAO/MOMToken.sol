pragma solidity ^0.4.18;
import "./SafeMath.sol";


contract ERC20Token {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract StandardToken is ERC20Token {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
}


contract MOMToken is StandardToken {
    using SafeMath for uint256;

    string public constant name = "MOM Token";
    string public constant symbol = "MOM";
    uint8 public constant decimals = 18;

    uint256 public totalLockedTokens;
    mapping(address => uint256) lockedTokens;

    function lock(uint256 _amount) public {
        require(_amount > 0);
        uint256 newLockedAmount = lockedTokens[msg.sender].add(_amount);
        require(newLockedAmount <= balances[msg.sender]);
        lockedTokens[msg.sender] = lockedTokens[msg.sender].add(_amount);
        totalLockedTokens = totalLockedTokens.add(_amount);
    }

    function unlock(uint256 _amount) public {
        require(_amount > 0 && _amount <= lockedTokens[msg.sender]);
        lockedTokens[msg.sender] = lockedTokens[msg.sender].sub(_amount);
        totalLockedTokens = totalLockedTokens.sub(_amount);
    }

    // Override transfer and transferFrom functions to prevent transferring locked tokens  
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        uint256 availibleBalance = balances[msg.sender].sub(lockedTokens[msg.sender]);
        require(_value <= availibleBalance);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        uint256 availibleBalance = balances[_from].sub(lockedTokens[_from]);
        require(_value <= availibleBalance);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function lockedBalance(address _owner) public constant returns (uint256 lockedAmount) {
        return lockedTokens[_owner];
    }
}
