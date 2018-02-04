pragma solidity ^0.4.19;

import "./SmartTicketsHelper.sol";
import "./TicketTemplate.sol";

contract SmartTicketsCore is SmartTicketsHelper {
    
    struct Ticket {
        string eventName;
        string eventDescription;
        string ticketType;
        uint price;
        uint16 initialSupply;
        uint16 currentSupply;
        uint startVendingTime;
        uint endVendingTime;
        bool refundable;
        bool active;
        string metaDescription;
    }

    Ticket[] tickets;
    mapping (uint => address) ticketIdToCreator;
    mapping (uint => address) ticketIdToOwner;
    mapping (address => mapping (uint => uint)) ownerToTicketId;
    mapping (address => uint) ticketCountOfOwner;
    mapping (address => uint) ticketCountOfCreator;
    
    mapping (address => uint) balanceOfCreator;
    
    modifier validOwnerOf(uint _ticketId) {
        require(ticketIdToOwner[_ticketId] == msg.sender);
        _;
    }
    
    modifier validCreatorOf(uint _ticketId) {
        require(ticketIdToCreator[_ticketId] == msg.sender);
        _;
    }
    

    function SmartTicketsCore() public {
        // Add the contract owner as CEO, COO, CFO and admin initially
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        admins[msg.sender] = 1;
    }

    function buyTicket(uint _ticketId, address _ticketFor) public payable returns(uint) {
        Ticket storage ticket = tickets[_ticketId];
        // Check if ticketStore exists
        require(ticketIdToCreator[_ticketId] != address(0));
        // require(ticket.startVendingTime < now && ticket.endVendingTime > now);
        require(ticket.currentSupply > 0);
        
        require(msg.value >= ticket.price);

        if (_ticketFor == address(0)) {
            _ticketFor = msg.sender;
        }
        
        // Pay the ticket price to the eventCreator
        ticketIdToCreator[_ticketId].transfer(ticket.price);
        // Return the remaining money in case more than enough money is sent
        msg.sender.transfer(msg.value - ticket.price);
        ownerToTicketId[_ticketFor][_ticketId]++;
        ticket.currentSupply--;
        ticketCountOfOwner[_ticketFor]++;
        
        return ticketCountOfOwner[_ticketFor];
    }
    
    // TODO: implement refund functionnality (might need to make Ticket to contract)
    // function refundTicket(uint _ticketId) external validOwnerOf(_ticketId) {
    //     Ticket storage ticket = tickets[_ticketId];
    //     require(ticket.refundable);
        
        
    // }

    function createTicket(
        address _creator,
        string _eventName,
        string _eventDescription,
        string _ticketType,
        uint _price,
        uint16 _initialSupply,
        uint16 _startVendingTime,
        uint _endVendingTime,
        bool _refundable,
        string _metaDescription
    ) 
        public
        onlyAdmin
        returns (uint)
    {
        require(bytes(_eventName).length > 0);
        require(_initialSupply > 0);
        
        if (_creator == address(0)) {
            _creator = msg.sender;
        }

        Ticket memory newTicket = Ticket(
            _eventName,
            _eventDescription,
            _ticketType,
            _price,
            _initialSupply,
            _initialSupply,
            _startVendingTime,
            _endVendingTime,
            _refundable,
            false,
            _metaDescription);
        
        uint newTicketId = tickets.push(newTicket) - 1;
        ticketIdToCreator[newTicketId] = _creator;
        
        return newTicketId;
    }

    function activateTicket(uint _ticketId) external validCreatorOf(_ticketId) {
        Ticket storage ticket = tickets[_ticketId];
        ticket.active = true;
    }

    function deactivateTicket(uint _ticketId) external validCreatorOf(_ticketId) {
        Ticket storage ticket = tickets[_ticketId];
        ticket.active = false;
    }
    
    // function promoteTicket(uint _ticketId) public payable {
        
    // }
    
    function getTicket(uint _ticketId) 
        external
        view 
        returns(
        string eventName,
        string eventDescription,
        string ticketType,
        uint price,
        uint16 initialSupply,
        uint16 currentSupply,
        uint startVendingTime,
        uint endVendingTime,
        bool refundable,
        bool active,
        string metaDescription
    ) 
    {
        Ticket storage ticket = tickets[_ticketId];
        
        eventName = ticket.eventName;
        eventDescription = ticket.eventDescription;
        ticketType = ticket.ticketType;
        price = ticket.price;
        initialSupply = ticket.initialSupply;
        currentSupply = ticket.currentSupply;
        startVendingTime = ticket.startVendingTime;
        endVendingTime = ticket.endVendingTime;
        refundable = ticket.refundable;
        active = ticket.active;
        metaDescription = metaDescription;
    }
}