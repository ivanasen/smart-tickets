pragma solidity ^0.4.19;

import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract TicketTemplate is Ownable {
    string public eventName;
    string public eventDescription;
    string public ticketType;
    uint public price;
    uint16 public initialSupply;
    uint16 public currentSupply;
    uint public startVendingTime;
    uint public endVendingTime;
    bool public refundable;
    bool public active;
    string public metaDescription;
    
    function buyTicket(address _for) external payable {
        
    }
    
    function refundTicket(uint _ticketId) {
        
    }
    
    function withdrawal() {
        require(!active);
    }
    
    function activate() onlyOwner {
        active = true;
    }
    
    function deactivate() onlyOwner {
        active = false;
    }
}
