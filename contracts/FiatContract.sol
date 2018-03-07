pragma solidity ^0.4.19;

contract FiatContract {
    function ETH(uint _id) public constant returns (uint256);
    function USD(uint _id) public constant returns (uint256);
    function EUR(uint _id) public constant returns (uint256);
    function GBP(uint _id) public constant returns (uint256);
    function updatedAt(uint _id) public constant returns (uint);
}

contract FiatContractTest is FiatContract {
    function ETH(uint _id) public constant returns (uint256) {
        return 13333333333333;
    }
    
    function USD(uint _id) public constant returns (uint256) {
        return 13333333333333;
    }
    
    function EUR(uint _id) public constant returns (uint256) {
        return 13333333333333;
    }
    
    function GBP(uint _id) public constant returns (uint256) {
        return 13333333333333; 
    }
    
    function updatedAt(uint _id) public constant returns (uint) {
        return 13333333333333;
    }
}