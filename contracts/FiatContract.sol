pragma solidity ^0.4.20;

contract FiatContract {
    function ETH(uint _id) constant returns (uint256);
    function USD(uint _id) constant returns (uint256);
    function EUR(uint _id) constant returns (uint256);
    function GBP(uint _id) constant returns (uint256);
    function updatedAt(uint _id) constant returns (uint);
}

contract FiatContractTest is FiatContract {
    function ETH(uint _id) constant returns (uint256) {
        return 1;
    }
    
    function USD(uint _id) constant returns (uint256) {
        return 1;
    }
    
    function EUR(uint _id) constant returns (uint256) {
        return 1;
    }
    
    function GBP(uint _id) constant returns (uint256) {
        return 1;
    }
    
    function updatedAt(uint _id) constant returns (uint) {
        return 1;
    }
}