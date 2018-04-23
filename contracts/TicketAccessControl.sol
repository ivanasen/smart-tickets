pragma solidity 0.4.23;

import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract TicketAccessControl is Ownable {

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    mapping(address => bool) admins;

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

    modifier onlyAdminOrAbove() {
        // Disable for testing purposes
        // require(eventOrganizers[msg.sender] == true || 
        //     msg.sender == cooAddress ||
        //     msg.sender == ceoAddress ||
        //     msg.sender == cfoAddress);
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

    function addAdmin(address _admin) external onlyCLevel {
        require(_admin != address(0));
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyCLevel {
        admins[_admin] = false;
    }

    function setNewAddress(address _v2Address) external onlyCEO {
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }
}