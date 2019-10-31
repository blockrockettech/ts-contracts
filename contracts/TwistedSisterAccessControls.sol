pragma solidity ^0.5.12;

import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";

import "./interfaces/ITwistedSisterAccessControls.sol";

contract TwistedSisterAccessControls is ITwistedSisterAccessControls, WhitelistedRole {
    constructor () public {
        super.addWhitelisted(msg.sender);
    }
}
