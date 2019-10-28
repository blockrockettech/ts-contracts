pragma solidity ^0.5.0;

contract ITwistedSisterAccessControls {
    function isWhitelisted(address account) public view returns (bool);

    function isWhitelistAdmin(address account) public view returns (bool);
}
