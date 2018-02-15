pragma solidity ^0.4.18;

contract TestContract {
   uint256 public value;

    function callMe() public payable {
        value = 1;
    }
}
