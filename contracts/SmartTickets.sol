pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract SmartTicketsCore is Pausable {    

    enum EventStatus {
        PASSED, NOT_PASSED, CANCELLED
    }

    struct TicketStore {
        uint initialSupply;
        uint currentSupply;
        uint price;
        string name;
        string description;
        address creator;
        string metaDescription;
        EventStatus status;
    }

    mapping (address => uint8) admins;

    TicketStore[] ticketStores;    
    mapping (uint => address) ticketStoreIdToCreator;
    mapping (uint => address) ticketToOwner;
    mapping (address => mapping (uint => uint)) ownerToTicketId;
    mapping (address => uint) ticketBalanceOf;

    modifier onlyAdmin() {
        require(admins[msg.sender] == 1);
        _;
    }

    function SmartTicketsCore() public {
        admins[msg.sender] = 1;
    }

    function buyTicket(uint _ticketId, address _ticketFor) external payable {
        TicketStore storage ticketStore = ticketStores[_ticketId];
        // Check if ticketStore exists
        require(ticketStore.creator != address(0));
        require(ticketStore.status == EventStatus.NOT_PASSED);
        require(msg.value == ticketStore.price);
        require(ticketStore.currentSupply > 0);

        if (_ticketFor == address(0)) {
            ownerToTicketId[msg.sender][_ticketId]++;
            ticketStore.creator.send(ticketStore.price);
            ticketStore.currentSupply--;
        }
    }

    function createTicket(
        uint _initialSupply,
        uint _price,
        string _metaDescription,
        uint8 _status,
        address _creator) public onlyAdmin returns(bool) {
        return true;
    }

    function activateTicket() onlyAdmin {}

    function deactivateTicket() onlyAdmin {}
    
}