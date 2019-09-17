pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedArtistCommissionRegistry.sol";
import "./interfaces/ITwistedAccessControls.sol";

contract TwistedArtistCommissionRegistry is ITwistedArtistCommissionRegistry {
    using SafeMath for uint256;

    ITwistedAccessControls accessControls;

    address payable[] public artists;

    // Artist address <> commission percentage
    mapping(address => uint256) public artistCommissionSplit;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedAccessControls _accessControls) public {
        accessControls = _accessControls;
    }

    function getCommissionSplits() public view returns (uint256[] memory _percentages, address payable[] memory _recipients) {
        require(artists.length > 0, "No artists have been registered");
        _percentages = new uint256[](artists.length);
        _recipients = new address payable[](artists.length);

        for(uint256 i = 0; i < artists.length; i++) {
            address payable artist = artists[i];
            _percentages[i] = artistCommissionSplit[artist];
            _recipients[i] = artist;
        }
    }
}