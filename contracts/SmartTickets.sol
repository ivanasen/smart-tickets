pragma solidity ^0.4.19;

import "./SmartTicketsHelper.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./FiatContract.sol";

contract SmartTickets is SmartTicketsHelper {
    using SafeMath for uint;
    
    event EventCreation(uint id, uint date, bytes metaDescriptionHash, address creator);
    event EventCancelation(uint id);
    
    event TicketTypeCreation(
        uint ticketTypeId,
        uint eventId,
        uint price,
        uint supply,
        bool refundable
    );
    event TicketPurchase(uint ticketId, address buyer);
    
    event Withdrawal(uint to, uint amount);
    
    struct TicketType {
        uint eventId;
        uint priceInUSDCents;
        uint initialSupply;
        uint currentSupply;
        bool refundable;
    }
    
    struct Event {
        uint date;
        bytes metaDescriptionHash;
        uint earnings;
        bool canceled;
    }
    
    FiatContract public fiatContract;
    address fiatContractAddress = 
        0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909;
    uint private FIAT_ETH_INDEX = 0;
    
    uint private currentTicketIdIndex;

    TicketType[] ticketTypes;
    Event[] events;
    mapping (uint => uint[]) eventToTicketType;
    mapping (uint => uint) ticketToTicketType;
    
    mapping (uint => address) eventIdToCreator;
    
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

    function SmartTickets() public {
        // Add the contract owner as CEO, COO, CFO and admin initially
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        eventOrganizers[msg.sender] = true;
        
        // fiatContract = FiatContract(fiatContractAddress);
        fiatContract = new FiatContractTest();
        
        // Create genesis event
        Event memory genesisEvent = Event(0, "", 0, false);
        events.push(genesisEvent);
        // Create genesis ticketType
        TicketType memory genesisTicketType = TicketType(0, 0, 0, 0, false);
        ticketTypes.push(genesisTicketType);
        // And genesis ticket
        currentTicketIdIndex = currentTicketIdIndex.add(1);
    }
    
    function setFiatContractAddress(address _newAddress) external onlyCEO {
        fiatContractAddress = _newAddress;
        fiatContract = FiatContract(_newAddress);
    }
    
    function balanceOf(address _owner) public view returns (uint) {
        return ownedTickets[_owner].length;
    }
    
    function getTicketIdForOwner(address _owner, uint _index) 
        public
        view
        returns(uint) {
        require(ownedTickets[_owner][_index] != 0);
        return ownedTickets[_owner][_index];
    }
    
    function getUsdCourse() public view returns (uint) {
        return fiatContract.USD(0);
    }
    
    function buyTicket(uint _ticketTypeId) public payable {
        TicketType storage ticketType = ticketTypes[_ticketTypeId];
        
        // Ensure the ticketType exists
        require(ticketType.eventId != 0);
        
        require(events[ticketType.eventId].date > now);
        require(ticketType.currentSupply > 0);
        
        require(msg.value == 
            ticketType.priceInUSDCents * fiatContract.USD(FIAT_ETH_INDEX));
        
        Event storage forEvent = events[ticketType.eventId];
        forEvent.earnings = forEvent.earnings.add(ticketType.priceInUSDCents);
        
        ticketType.currentSupply = ticketType.currentSupply.sub(1);
        
        uint newTicketId = currentTicketIdIndex;
        
        ticketOwner[newTicketId] = msg.sender;
        ticketToTicketType[newTicketId] = _ticketTypeId;
        uint length = balanceOf(msg.sender);
        ownedTickets[msg.sender].push(currentTicketIdIndex);
        ownedTicketsIndex[currentTicketIdIndex] = length;
        
        currentTicketIdIndex = currentTicketIdIndex.add(1);
        TicketPurchase(currentTicketIdIndex - 1, msg.sender);
    }
    
    function createEvent(uint _date,
        bytes _metaDescriptionHash,
        uint[] _ticketPricesInUSDCents,
        uint[] _ticketSupplies,
        bool[] _ticketRefundables) external {
        require(_date > now);
        require(_ticketPricesInUSDCents.length > 0 &&
            _ticketPricesInUSDCents.length == _ticketSupplies.length &&
            _ticketPricesInUSDCents.length == _ticketRefundables.length);
        
        Event memory newEvent = Event(
            _date,
            _metaDescriptionHash,
            0,
            false);
        uint newEventId = events.push(newEvent) - 1;
        eventIdToCreator[newEventId] = msg.sender;
        
        EventCreation(newEventId, _date, _metaDescriptionHash, msg.sender);
        
        for (uint i = 0; i < _ticketPricesInUSDCents.length; i++) {
            addTicketForEvent(
                newEventId,
                _ticketPricesInUSDCents[i],
                _ticketSupplies[i],
                _ticketRefundables[i]);
        }
    }
    
    function addTicketForEvent(
        uint _eventId,
        uint _priceInUSDCents,
        uint _initialSupply,
        bool _refundable
    )
        public
        validCreatorOfEvent(_eventId)
    {
        require(_initialSupply > 0);
        
        TicketType memory ticketType = TicketType(
            _eventId,
            _priceInUSDCents,
            _initialSupply,
            _initialSupply,
            _refundable
        );
        
        uint length = ticketTypes.push(ticketType);
        uint ticketTypeId =  length - 1;
        
        eventToTicketType[_eventId].push(ticketTypeId);
        
        TicketTypeCreation(
            ticketTypeId,
            _eventId,
            _priceInUSDCents,
            _initialSupply,
            _refundable
        );
    }
    
    function refundTicket(uint _ticketId) external onlyOwnerOf(_ticketId) {
        TicketType storage ticketType = 
            ticketTypes[ticketToTicketType[_ticketId]];
        Event storage forEvent = events[ticketType.eventId];
        
        require(forEvent.canceled || ticketType.refundable);
        
        ticketType.currentSupply = ticketType.currentSupply.add(1);
        forEvent.earnings = forEvent.earnings.sub(ticketType.priceInUSDCents);
        
        ticketOwner[_ticketId] = address(0);
        ownedTickets[msg.sender][ownedTicketsIndex[_ticketId]] = 0;
        ownedTicketsIndex[_ticketId] = 0;
        
        msg.sender.transfer(ticketType.priceInUSDCents * fiatContract.USD(0));
    }
    
    function cancelEvent(uint _eventId) external validCreatorOfEvent(_eventId) {
        Event storage eventToCancel = events[_eventId];
        require(eventToCancel.date > now);
        eventToCancel.canceled = true;
        EventCancelation(_eventId);
    }
    
    function withdrawalEarningsForEvent(uint _eventId) 
        external
        validCreatorOfEvent(_eventId)
    {
        Event storage pastEvent = events[_eventId];
        require(pastEvent.date > now);
        
        msg.sender.transfer(pastEvent.earnings);
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
        // Exclude genesis event
        return events.length.sub(1);
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
        uint ticketTypeId,
        uint eventId,
        uint price,
        uint initialSupply,
        uint currentSupply,
        bool refundable
    ) {
        TicketType storage ticketType = ticketTypes[_ticketTypeId];
        
        ticketTypeId = _ticketTypeId;
        eventId = ticketType.eventId;
        price = ticketType.priceInUSDCents;
        initialSupply = ticketType.initialSupply;
        currentSupply = ticketType.currentSupply;
        refundable = ticketType.refundable;
    }
    
    function getEvent(uint _eventId) 
        external 
        view 
        returns(
        uint date,
        bytes metaDescriptionHash,
        bool canceled,
        uint ticketTypeCount,
        uint earnings
    ) {
        require(eventIdToCreator[_eventId] != address(0));
        
        Event storage searchedEvent = events[_eventId];
        date = searchedEvent.date;
        metaDescriptionHash = searchedEvent.metaDescriptionHash;
        canceled = searchedEvent.canceled;
        ticketTypeCount = eventToTicketType[_eventId].length;
        earnings = searchedEvent.earnings;
    }
    
    function getTicketTypeForTicket(uint _ticketId) 
        external
        view
        returns(
        uint,
        uint,
        uint,
        uint,
        uint,
        bool
    ) {
        uint256 ticketTypeId = ticketToTicketType[_ticketId];
        return getTicketType(ticketTypeId);
    }
    
    function getTicketTypeForEvent(uint _eventId, uint _index)
        external
        view
        returns(uint, uint, uint, uint, uint, bool) {
        uint ticketTypeId = eventToTicketType[_eventId][_index];
        return getTicketType(ticketTypeId);
    }
    
    function getTicketTypeCount() public view returns(uint) {
        // Exclude genesis ticketType
        return ticketTypes.length - 1;
    }
    
    function getOneUSDCentInWei() public view returns(uint) {
        return fiatContract.USD(FIAT_ETH_INDEX);
    }
}