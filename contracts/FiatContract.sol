pragma solidity 0.4.23;

contract FiatContract {
    function ETH(uint _id) public constant returns (uint256);
    function USD(uint _id) public constant returns (uint256);
    function EUR(uint _id) public constant returns (uint256);
    function GBP(uint _id) public constant returns (uint256);
    function updatedAt(uint _id) public constant returns (uint);
}

contract FiatContractDebug is FiatContract {
    function ETH(uint _price) public constant returns (uint256) {
        return 1;
    }

    function USD(uint _id) public constant returns (uint256) {
        return 1;
    }

    function EUR(uint _id) public constant returns (uint256) {
        return 1;
    }

    function GBP(uint _id) public constant returns (uint256) {
        return 1;
    }

    function updatedAt(uint _id) public constant returns (uint) {
        return 1;
    }
}