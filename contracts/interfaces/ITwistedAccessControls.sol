pragma solidity ^0.5.0;

contract ITwistedAccessControls {
    function isWhitelisted(address account) public view returns (bool);

    function isWhitelistAdmin(address account) public view returns (bool);
}