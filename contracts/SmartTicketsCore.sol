pragma solidity ^0.4.19;

import "./SmartTicketsHelper.sol";

contract SmartTicketsCore is SmartTicketsHelper {
    
    uint constant MAX_TICKET_PRICE = 5 ether;
    
    event EventCreation(uint id, uint date, bytes metaDescriptionHash, address creator);
    event EventCancelation(uint id);
    
    event TicketCreation(
        uint ticketId,
        uint eventId,
        uint price,
        uint supply,
        uint startVendingTime,
        uint endVendingTime,
        bool refundable,
        address creator
    );
    event TicketPurchase(uint ticketId, address buyer);
    
    event Withdrawal(uint to, uint amount);
    
    
    struct Ticket {
        uint eventId;
        uint price;
        uint16 initialSupply;
        uint16 currentSupply;
        uint startVendingTime;
        uint endVendingTime;
        bool refundable;
    }
    
    struct Event {
        uint date;
        bytes metaDescriptionHash;
    }

    Ticket[] tickets;
    Event[] events;
    
    mapping (uint => address) eventIdToCreator;
    mapping (uint => address) ticketIdToCreator;
    mapping (address => mapping (uint => uint)) ownerToTicket;
    
    modifier validOwnerOf(uint _ticketId) {
        require(ownerToTicket[msg.sender][_ticketId] > 0);
        _;
    }
    
    modifier validCreatorOfEvent(uint _id) {
        require(eventIdToCreator[_id] == msg.sender);
        _;
    }
    
    modifier validCreatorOfTicket(uint _id) {
        require(ticketIdToCreator[_id] == msg.sender);
        _;
    }
    

    function SmartTicketsCore() public {
        // Add the contract owner as CEO, COO, CFO and admin initially
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        admins[msg.sender] = 1;
    }
    
    function buyTicket(uint _ticketId) public payable {
        Ticket storage ticket = tickets[_ticketId];
        
        require(ticketIdToCreator[_ticketId] != address(0));
        require(events[ticket.eventId].date > now);
        require(ticket.currentSupply > 0);
        require(msg.value >= ticket.price);
        
        ticketIdToCreator[_ticketId].transfer(ticket.price);
        msg.sender.transfer(msg.value - ticket.price);
        ticket.currentSupply--;
        ownerToTicket[msg.sender][_ticketId]++;
        
        TicketPurchase(_ticketId, msg.sender);
    }
    
    function createEvent(
        uint _date,
        bytes _metaDescriptionHash
    ) external {
        require(_date > now);
        
        Event memory newEvent = Event(_date, _metaDescriptionHash);
        uint newEventId = events.push(newEvent) - 1;
        eventIdToCreator[newEventId] = msg.sender;
        
        EventCreation(newEventId, _date, _metaDescriptionHash, msg.sender);
    }
    
    function addTicketForEvent(
        uint _eventId,
        uint _priceInEther,
        uint16 _initialSupply,
        uint _startVendingTime,
        uint _endVendingTime,
        bool _refundable
    )
        external
        validCreatorOfEvent(_eventId)
    {
        require(_priceInEther <= MAX_TICKET_PRICE);
        require(_initialSupply > 0);
        require(_startVendingTime > now);
        require(_endVendingTime > _startVendingTime);
        
        Ticket memory newTicket = Ticket(
            _eventId,
            _priceInEther,
            _initialSupply,
            _initialSupply,
            _startVendingTime,
            _endVendingTime,
            _refundable
        );
        
        uint newTicketId = tickets.push(newTicket) - 1;
        ticketIdToCreator[newTicketId] = msg.sender;
        
        TicketCreation(
            newTicketId,
            _eventId,
            _priceInEther,
            _initialSupply,
            _startVendingTime,
            _endVendingTime,
            _refundable,
            msg.sender
        );
    }
    
    function setEventDate(uint _id, uint _date)
        external
        validCreatorOfEvent(_id)
    {
        require(_date > now);
        events[_id].date = _date;
    }
    
    function setEventMetaDescriptionHash(uint _id, bytes _hash)
        external 
        validCreatorOfEvent(_id)
    {
        events[_id].metaDescriptionHash = _hash;
    }
    
    function getEvent(uint _id) 
        external 
        view 
        returns(
        uint date,
        bytes metaDescriptionHash
    )
    {
        Event storage searchedEvent = events[_id];
        
        date = searchedEvent.date;
        metaDescriptionHash = searchedEvent.metaDescriptionHash;
    }
    
    function getTicket(uint _ticketId) 
        external
        view
        returns(
        uint eventId,
        uint price,
        uint16 initialSupply,
        uint16 currentSupply,
        uint startVendingTime,
        uint endVendingTime,
        bool refundable
    ) 
    {
        Ticket storage ticket = tickets[_ticketId];
        
        eventId = ticket.eventId;
        price = ticket.price;
        initialSupply = ticket.initialSupply;
        currentSupply = ticket.currentSupply;
        startVendingTime = ticket.startVendingTime;
        endVendingTime = ticket.endVendingTime;
        refundable = ticket.refundable;
    }
}