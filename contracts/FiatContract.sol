pragma solidity 0.4.23;

contract FiatContract {
    function ETH(uint _id) public constant returns (uint256);
    function USD(uint _id) public constant returns (uint256);
    function EUR(uint _id) public constant returns (uint256);
    function GBP(uint _id) public constant returns (uint256);
    function updatedAt(uint _id) public constant returns (uint);
}

contract FiatContractDebug is FiatContract {
    // Adding the id in order to remove the unused variable warning
    function ETH(uint _id) public constant returns (uint256) {
        return 1000000 + _id;
    }

    function USD(uint _id) public constant returns (uint256) {
        return 1000000 + _id;
    }

    function EUR(uint _id) public constant returns (uint256) {
        return 1000000 + _id;
    }

    function GBP(uint _id) public constant returns (uint256) {
        return 1000000 + _id;
    }

    function updatedAt(uint _id) public constant returns (uint) {
        return 1000000 + _id;
    }
}