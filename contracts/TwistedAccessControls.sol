pragma solidity ^0.5.0;

import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";

import "./interfaces/ITwistedAccessControls.sol";

contract TwistedAccessControls is ITwistedAccessControls, WhitelistedRole {
    constructor () public {
        super.addWhitelisted(msg.sender);
    }
}