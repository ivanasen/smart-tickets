pragma solidity 0.4.23;

import "./TicketAccessControl.sol";
import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "./FiatContract.sol";

contract SmartTickets is TicketAccessControl {
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
        bool cancelled;
        bool[] seats;
        PromotionLevel promotionLevel;
        uint promotionExpirationDate;
    }
    
    FiatContract public fiatContract;
    address fiatContractAddress = 0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909;
    uint private FIAT_ETH_INDEX = 0;
    
    enum PromotionLevel { NONE, SMALL, MEDIUM, BIG }
    mapping (uint8 => uint) promotionLevelPrices;

    TicketType[] ticketTypes;
    Event[] events;
    uint private currentTicketIdIndex;
    mapping (uint => uint16) ticketToSeat;
    mapping (uint => uint[]) eventToTicketType;
    mapping (uint => uint) ticketToTicketType;
    
    mapping (uint => address) eventIdToCreator;
    mapping (address => uint) creatorEventCount;
    
    mapping (uint => address) ticketOwner;
    mapping (address => uint[]) private ownedTickets;
    mapping (uint => uint) private ownedTicketsIndex;
    
    
    modifier onlyOwnerOf(uint _ticketId) {
        require(ticketOwner[_ticketId] == msg.sender);
        _;
    }
    
    modifier validCreatorOfEvent(uint _eventId) {
        require(eventIdToCreator[_eventId] == msg.sender);
        _;
    }
    
    modifier validPromotionLevel(PromotionLevel _level) {
        require(_level == PromotionLevel.SMALL || 
            _level == PromotionLevel.MEDIUM ||
            _level == PromotionLevel.BIG);
        _;
    }

    constructor() public {
        // Add the contract owner as CEO, COO, CFO and admin initially
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        admins[msg.sender] = true;
        
        fiatContract = FiatContract(fiatContractAddress);
        
        // Create genesis event
        Event memory genesisEvent = Event(0, 
            "",
            0, 
            false, 
            new bool[](0),
            PromotionLevel.NONE,
            0);
        events.push(genesisEvent);
        // Create genesis ticketType
        TicketType memory genesisTicketType = TicketType(0, 0, 0, 0, false);
        ticketTypes.push(genesisTicketType);
        // And genesis ticket
        currentTicketIdIndex = currentTicketIdIndex.add(1);
        
        // Set initial promotion level prices
        promotionLevelPrices[uint8(PromotionLevel.SMALL)] = fiatContract.USD(10);
        promotionLevelPrices[uint8(PromotionLevel.MEDIUM)] = fiatContract.USD(20);
        promotionLevelPrices[uint8(PromotionLevel.BIG)] = fiatContract.USD(30);
    }
    
    function setFiatContractAddress(address _newAddress) external onlyCLevel {
        fiatContractAddress = _newAddress;
        fiatContract = FiatContract(_newAddress);
    }
    
    function balanceOf(address _owner) public view returns (uint) {
        return ownedTickets[_owner].length;
    }
    
    function getTicketsForOwner(address _owner) public view returns (uint[]) {
        return ownedTickets[_owner];
    }
    
    function getTicketIdForOwner(address _owner, uint _index) 
        public
        view
        returns(uint)
    {
        require(ownedTickets[_owner][_index] != 0);
        return ownedTickets[_owner][_index];
    }
    
    function getUsdCourse() public view returns (uint) {
        return fiatContract.USD(0);
    }
    
    function buyTicket(uint _ticketTypeId, uint16 _seatIndex) public payable {
        TicketType storage ticketType = ticketTypes[_ticketTypeId];
        Event storage forEvent = events[ticketType.eventId];
        
        require(ticketType.eventId != 0);
        require(events[ticketType.eventId].date > now);
        require(ticketType.currentSupply > 0);
        require(!forEvent.seats[_seatIndex]);
        require(msg.value ==
            ticketType.priceInUSDCents * fiatContract.USD(FIAT_ETH_INDEX));
        
        
        forEvent.earnings = forEvent.earnings.add(msg.value);
        ticketType.currentSupply = ticketType.currentSupply.sub(1);
        forEvent.seats[_seatIndex] = true;
        ticketToSeat[currentTicketIdIndex] = _seatIndex;
        
        ticketOwner[currentTicketIdIndex] = msg.sender;
        ticketToTicketType[currentTicketIdIndex] = _ticketTypeId;
        uint length = balanceOf(msg.sender);
        ownedTickets[msg.sender].push(currentTicketIdIndex);
        ownedTicketsIndex[currentTicketIdIndex] = length;
        
        currentTicketIdIndex = currentTicketIdIndex.add(1);
        emit TicketPurchase(currentTicketIdIndex - 1, msg.sender);
    }
    
    function createEvent(uint _date,
        bytes _metaDescriptionHash,
        uint[] _ticketPricesInUSDCents,
        uint[] _ticketSupplies,
        bool[] _ticketRefundables,
        uint16 _seatCount) 
        external
        onlyAdminOrAbove
    {
        require(_date > now);
        require(_ticketPricesInUSDCents.length > 0 &&
            _ticketPricesInUSDCents.length == _ticketSupplies.length &&
            _ticketPricesInUSDCents.length == _ticketRefundables.length);
        require(_seatCount > 0);
        
        Event memory newEvent = Event(
            _date,
            _metaDescriptionHash,
            0,
            false,
            new bool[](_seatCount),
            PromotionLevel.NONE,
            0);
        uint newEventId = events.push(newEvent) - 1;
        eventIdToCreator[newEventId] = msg.sender;
        creatorEventCount[msg.sender] = creatorEventCount[msg.sender].add(1);
        
        emit EventCreation(newEventId, _date, _metaDescriptionHash, msg.sender);
        
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
        
        emit TicketTypeCreation(
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
        
        require(forEvent.cancelled || ticketType.refundable);
        
        ticketType.currentSupply = ticketType.currentSupply.add(1);
        forEvent.earnings = forEvent.earnings.sub(ticketType.priceInUSDCents);
        forEvent.seats[ticketToSeat[_ticketId]] = false;
        
        ticketOwner[_ticketId] = address(0);
        ownedTickets[msg.sender][ownedTicketsIndex[_ticketId]] = 0;
        ownedTicketsIndex[_ticketId] = 0;
        
        msg.sender.transfer(ticketType.priceInUSDCents * fiatContract.USD(0));
    }
    
    function cancelEvent(uint _eventId) external validCreatorOfEvent(_eventId) {
        Event storage eventToCancel = events[_eventId];
        require(eventToCancel.date > now);
        eventToCancel.cancelled = true;
        emit EventCancelation(_eventId);
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
    
    function setPromotionLevelPrice(PromotionLevel _level, uint _newPrice) 
        external
        validPromotionLevel(_level)
        onlyCLevel {
        promotionLevelPrices[uint8(_level)] = fiatContract.USD(_newPrice);
    }
    
    function promoteEvent(uint _eventId, PromotionLevel _level, uint8 _numDays)
        validCreatorOfEvent(_eventId)
        validPromotionLevel(_level)
        external
        payable {
        Event storage forEvent = events[_eventId];
        require(!forEvent.cancelled || forEvent.date > now);
        
        uint price = _numDays * promotionLevelPrices[uint8(_level)];
        require(msg.value == fiatContract.ETH(price));
        
        forEvent.promotionLevel = _level;
        forEvent.promotionExpirationDate = now + (_numDays * 1 days);
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
        bool cancelled,
        uint ticketTypeCount,
        uint earnings
    ) {
        require(eventIdToCreator[_eventId] != address(0));
        
        Event storage searchedEvent = events[_eventId];
        date = searchedEvent.date;
        metaDescriptionHash = searchedEvent.metaDescriptionHash;
        cancelled = searchedEvent.cancelled;
        ticketTypeCount = eventToTicketType[_eventId].length;
        earnings = searchedEvent.earnings;
    }

    function getEventIdsForCreator(address _creator) external view returns(uint[]) {
        require(_creator != address(0));
        
        uint[] memory resultEvents = new uint[](creatorEventCount[_creator]);
        uint resultIndex = 0;
        for (uint i = 1; i < events.length; i++) {
            if (eventIdToCreator[i] == _creator) {
                resultEvents[resultIndex++] = i;
            }
        }
        return resultEvents;
    }
    
    function getEventSeats(uint _eventId)
        external
        view
        returns(bool[]) {
        Event storage searchedEvent = events[_eventId];
        require(searchedEvent.seats.length > 0);
        return searchedEvent.seats;
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
        returns(uint, uint, uint, uint, uint, bool)
    {
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
    
    function verifyTicket(uint _ticketId, 
        bytes32 _ticketIdHash,
        address _addr,
        uint8 _v,
        bytes32 _r,
        bytes32 _s) 
        public
        view
        returns (bool) {
        require(msg.sender != address(0));
        
        bool isSigned = _isSigned(_addr, _ticketIdHash, _v, _r, _s);
        bool validOwner = ticketOwner[_ticketId] == _addr;
        return isSigned && validOwner;
    }
    
    function _isSigned(address _addr, 
        bytes32 _msgHash, 
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        private
        pure
        returns (bool) {
        return ecrecover(_msgHash, _v, _r, _s) == _addr;
    }
}