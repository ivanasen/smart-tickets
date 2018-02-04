pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/lifecycle/Pausable.sol";

contract TicketsAccessControl is Pausable {

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    mapping(address => uint8) admins;

    address public newContractAddress;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender] == 1);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function addAdmin(address _newAdmin) external onlyCEO {
        require(_newAdmin != address(0));
        admins[_newAdmin] = 1;
    }

    function removeAdmin(address _admin) external onlyCEO {
        admins[_admin] = 0;
    }

    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }
}

contract SmartTicketsCore is TicketsAccessControl {    

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

    function createTicketStore(
        uint _initialSupply,
        uint _price,
        string _name,
        string _description,
        string _metaDescription,
        uint8 _status,
        address _creator) 
        public 
        onlyAdmin 
        returns (bool) {
        
        if (_creator == address(0)) {
            _creator = msg.sender;
        }

        TicketStore memory newTicket = TicketStore(
            _initialSupply,
            _initialSupply,
            _price,
            _name,
            _description,
            _creator,
            _metaDescription,
            EventStatus.NOT_PASSED);
        
        uint ticketId = ticketStores.push(newTicket) - 1;
        ticketStoreIdToCreator[ticketId] = _creator;
        return true;
    }

    function activateTicket(uint _ticketId) onlyAdmin {}

    function deactivateTicket(uint _ticketId) onlyAdmin {}    
}