pragma solidity ^0.4.19;

import "./SmartTicketsHelper.sol";

contract SmartTicketsCore is SmartTicketsHelper {
    
    struct Ticket {
        uint eventId;
        string title;
        string ticketType;
        uint price;
        uint16 initialSupply;
        uint16 currentSupply;
        uint startVendingTime;
        uint endVendingTime;
        bool refundable;
    }
    
    struct Event {
        string name;
        uint date;
        bytes metaDescriptionHash;
    }

    Ticket[] tickets;
    Event[] events;
    
    mapping (uint => address) eventIdToCreator;
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
    
    function buyTicket(uint _ticketId) public payable returns(uint) {
        Ticket storage ticket = tickets[_ticketId];
        
        require(ticketIdToCreator[_ticketId] != address(0));
        require(events[ticket.eventId].date > now);
        require(ticket.currentSupply > 0);
        require(msg.value >= ticket.price);
        
        ticketIdToCreator[_ticketId].transfer(ticket.price);
        msg.sender.transfer(msg.value - ticket.price);
        ticket.currentSupply--;
        ownerToTicketId[msg.sender][_ticketId]++;
        ticketCountOfOwner[msg.sender]++;
        
        return ticketCountOfOwner[msg.sender];
    }
    
    function createEvent(
        string _name,
        uint _date,
        bytes _metaDescriptionHash
    ) external returns (uint) {
        require(bytes(_name).length > 4);
        require(_date > now);
        
        Event memory newEvent = Event(_name, _date, _metaDescriptionHash);
        uint newEventId = events.push(newEvent) - 1;
        
        eventIdToCreator[newEventId] = msg.sender;
        
        return newEventId;
    }
    
    function addTicketForEvent(
        uint _eventId,
        string _title,
        string _ticketType,
        uint _priceInEther,
        uint16 _initialSupply,
        uint _startVendingTime,
        uint _endVendingTime,
        bool _refundable
    ) external returns (uint) {
        require(bytes(events[_eventId].name).length > 0);
        require(bytes(_title).length > 4);
        require(_initialSupply > 0);
        require(_startVendingTime > now);
        require(_endVendingTime > _startVendingTime);
        
        Ticket memory newTicket = Ticket(
            _eventId,
            _title,
            _ticketType,
            _priceInEther,
            _initialSupply,
            _initialSupply,
            _startVendingTime,
            _endVendingTime,
            _refundable
        );
        
        uint newTicketId = tickets.push(newTicket) - 1;
        ticketIdToCreator[newTicketId] = msg.sender;
        return newTicketId;
    }
    
    function setEventName(uint _id, string _name)
        external
        validCreatorOfEvent(_id)
    {
        require(bytes(_name).length > 4);
        events[_id].name = _name;
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
        string name,
        uint date,
        bytes metaDescriptionHash
    )
    {
        Event storage searchedEvent = events[_id];
        name = searchedEvent.name;
        date = searchedEvent.date;
        metaDescriptionHash = searchedEvent.metaDescriptionHash;
    }
    
    function getTicket(uint _ticketId) 
        external
        view
        returns(
        uint eventId,
        string title,
        string ticketType,
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
        title = ticket.title;
        ticketType = ticket.ticketType;
        price = ticket.price;
        initialSupply = ticket.initialSupply;
        currentSupply = ticket.currentSupply;
        startVendingTime = ticket.startVendingTime;
        endVendingTime = ticket.endVendingTime;
        refundable = ticket.refundable;
    }
}