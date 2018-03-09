pragma solidity ^0.4.19;

contract FiatContract {
    function ETH(uint _id) public constant returns (uint256);
    function USD(uint _id) public constant returns (uint256);
    function EUR(uint _id) public constant returns (uint256);
    function GBP(uint _id) public constant returns (uint256);
    function updatedAt(uint _id) public constant returns (uint);
}