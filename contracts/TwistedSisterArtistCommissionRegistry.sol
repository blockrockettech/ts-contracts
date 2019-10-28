pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedSisterArtistCommissionRegistry.sol";
import "./interfaces/ITwistedSisterAccessControls.sol";

contract TwistedSisterArtistCommissionRegistry is ITwistedSisterArtistCommissionRegistry {
    using SafeMath for uint256;

    ITwistedSisterAccessControls public accessControls;

    address payable[] public artists;

    uint256 public maxCommission = 10000;

    // Artist address <> commission percentage
    mapping(address => uint256) public artistCommissionSplit;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedSisterAccessControls _accessControls) public {
        accessControls = _accessControls;
    }

    function setCommissionSplits(uint256[] calldata _percentages, address payable[] calldata _artists) external isWhitelisted returns (bool) {
        require(_percentages.length == _artists.length, "Differing percentage or recipient sizes");

        // reset any existing splits
        for(uint256 i = 0; i < artists.length; i++) {
            address payable artist = artists[i];
            delete artistCommissionSplit[artist];
            delete artists[i];
        }
        artists.length = 0;

        uint256 total;

        for(uint256 i = 0; i < _artists.length; i++) {
            address payable artist = _artists[i];
            require(artist != address(0x0), "Invalid address");
            artists.push(artist);
            artistCommissionSplit[artist] = _percentages[i];
            total = total.add(_percentages[i]);
        }

        require(total == maxCommission, "Total commission does not match allowance");

        return true;
    }

    function getCommissionSplits() external view returns (uint256[] memory _percentages, address payable[] memory _artists) {
        require(artists.length > 0, "No artists have been registered");
        _percentages = new uint256[](artists.length);
        _artists = new address payable[](artists.length);

        for(uint256 i = 0; i < artists.length; i++) {
            address payable artist = artists[i];
            _percentages[i] = artistCommissionSplit[artist];
            _artists[i] = artist;
        }
    }

    function getMaxCommission() external view returns (uint256) {
        return maxCommission;
    }
}
