pragma solidity ^0.4.20;

import "./SmartTicketsHelper.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";

contract SmartTicketsCore is SmartTicketsHelper {
    using SafeMath for uint;
    
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
    
    struct TicketType {
        uint eventId;
        uint price;
        uint initialSupply;
        uint currentSupply;
        bool refundable;
    }
    
    struct Event {
        uint date;
        bytes metaDescriptionHash;
        bool canceled;
    }
    
    uint private totalTickets;

    TicketType[] ticketTypes;
    Event[] events;
    mapping(uint => uint) ticketToTicketType;
    
    mapping (uint => address) eventIdToCreator;
    mapping (address => mapping (uint => uint)) ownerToTicket;
    
    mapping (uint => address) ticketOwner;
    mapping (address => uint[]) private ownedTickets;
    mapping(uint => uint) private ownedTicketsIndex;
    
    modifier onlyOwnerOf(uint _ticketId) {
        require(ticketOwner[_ticketId] == msg.sender);
        _;
    }
    
    modifier validCreatorOfEvent(uint _eventId) {
        require(eventIdToCreator[_eventId] == msg.sender);
        _;
    }

    function SmartTicketsCore() public {
        // Add the contract owner as CEO, COO, CFO and admin initially
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        admins[msg.sender] = 1;
    }
    
    function balanceOf(address _owner) public view returns (uint) {
        return ownedTickets[_owner].length;
    }
    
    function buyTicket(uint _ticketTypeId) public payable {
        TicketType storage ticketType = ticketTypes[_ticketTypeId];
        
        // Ensure the ticketType exists
        require(eventIdToCreator[ticketType.eventId] != address(0));
        
        require(events[ticketType.eventId].date > now);
        require(ticketType.currentSupply > 0);
        
        require(msg.value >= ticketType.price);
        
        eventIdToCreator[ticketType.eventId].transfer(ticketType.price);
        msg.sender.transfer(msg.value - ticketType.price);
        ticketType.currentSupply = ticketType.currentSupply.sub(1);
        
        uint newTicketId = totalTickets;
        
        ticketOwner[newTicketId] = msg.sender;
        ticketToTicketType[newTicketId] = _ticketTypeId;
        uint length = balanceOf(msg.sender);
        ownedTickets[msg.sender].push(totalTickets);
        ownedTicketsIndex[totalTickets] = length;
        
        totalTickets = totalTickets.add(1);
        TicketPurchase(totalTickets - 1, msg.sender);
    }
    
    
    function createEvent(uint _date, bytes _metaDescriptionHash) external {
        require(_date > now);
        
        Event memory newEvent = Event(_date, _metaDescriptionHash, false);
        uint newEventId = events.push(newEvent) - 1;
        eventIdToCreator[newEventId] = msg.sender;
        
        EventCreation(newEventId, _date, _metaDescriptionHash, msg.sender);
    }
    
    function addTicketForEvent(
        uint _eventId,
        uint _priceInEther,
        uint _initialSupply,
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
        
        TicketType memory ticketType = TicketType(
            _eventId,
            _priceInEther,
            _initialSupply,
            _initialSupply,
            _refundable
        );
        
        uint length = ticketTypes.push(ticketType);
        uint ticketTypeId =  length.sub(1);
        
        TicketCreation(
            ticketTypeId,
            _eventId,
            _priceInEther,
            _initialSupply,
            _startVendingTime,
            _endVendingTime,
            _refundable,
            msg.sender
        );
    }
    
    function refundTicket(uint _ticketId) external onlyOwnerOf(_ticketId) {
        TicketType storage ticketType = 
            ticketTypes[ticketToTicketType[_ticketId]];
        Event storage cancelledEvent = events[ticketType.eventId];
        
        require(cancelledEvent.canceled);
        require(ticketType.refundable);
        msg.sender.transfer(ticketType.price);
    }
    
    function cancelEvent(uint _eventId) external validCreatorOfEvent(_eventId) {
        Event storage eventToCancel = events[_eventId];
        require(eventToCancel.date > now);
        eventToCancel.canceled = true;
        EventCancelation(_eventId);
    }
    
    function changeEventDate(uint _id, uint _date)
        external
        validCreatorOfEvent(_id)
    {
        require(_date > now);
        events[_id].date = _date;
    }
    
    function changeEventMetaDescriptionHash(uint _id, bytes _hash)
        external 
        validCreatorOfEvent(_id)
    {
        events[_id].metaDescriptionHash = _hash;
    }
    
    function getEventCount() external view returns(uint) {
        return events.length;
    }
    
    function getTicketTypesCountForEvent(uint _eventId) 
        external
        view
        returns(uint256 count)
    {
        require(eventIdToCreator[_eventId] != address(0));
        
        for (uint i = 0; i < ticketTypes.length; i++) {
            if (ticketTypes[i].eventId == _eventId) {
                count++;
            }
        }
    }
    
    function getTicketType(uint _ticketTypeId) 
        public
        view
        returns(
        uint eventId,
        uint price,
        uint initialSupply,
        uint currentSupply,
        bool refundable
    ) {
        TicketType storage ticketType = ticketTypes[_ticketTypeId];
        
        eventId = ticketType.eventId;
        price = ticketType.price;
        initialSupply = ticketType.initialSupply;
        currentSupply = ticketType.currentSupply;
        refundable = ticketType.refundable;
    }
    
    function getEvent(uint _id) 
        external 
        view 
        returns(
        uint date,
        bytes metaDescriptionHash,
        bool canceled
    ) {
        Event storage searchedEvent = events[_id];
        
        date = searchedEvent.date;
        metaDescriptionHash = searchedEvent.metaDescriptionHash;
        canceled = searchedEvent.canceled;
    }
    
    function getTicketTypeForTicket(uint _ticketId) 
        external
        view
        returns(
        uint,
        uint,
        uint,
        uint,
        bool
    ) {
        uint256 ticketTypeId = ticketToTicketType[_ticketId];
        return getTicketType(ticketTypeId);
    }
}