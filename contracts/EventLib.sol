pragma solidity ^0.4.19;

library EventLib {
    
    struct Event {
        string name;
        string description;
        uint date;
        bool active;
        bytes metaDescriptionHash;
    }
    
    function setEventName(Event self, string _name) public {
        require(bytes(_name).length > 4);
        self.name = _name;
    }
    
    function setEventDescription(Event self, string _description) public {
        self.description = _description;
    }
    
    function setEventDate(Event self, uint _date) public {
        require(_date > now);
        self.date = _date;
    }
    
    function setEventActivity(Event self, bool _active) public {
        self.active = _active;
    }
    
    function setEventMetaDescriptionHash(Event self, bytes _hash) public {
        self.metaDescriptionHash = _hash;
    }
}