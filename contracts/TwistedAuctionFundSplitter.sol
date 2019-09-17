pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedAuctionFundSplitter.sol";
import "./interfaces/ITwistedAccessControls.sol";
import "./interfaces/ITwistedArtistCommissionRegistry.sol";

contract TwistedAuctionFundSplitter is ITwistedAuctionFundSplitter {
    using SafeMath for uint256;

    event AuctionFundSplit(uint256 _round, uint256 _totalValue, address _caller);

    ITwistedAccessControls public accessControls;
    ITwistedArtistCommissionRegistry public artistCommissionRegistry;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedAccessControls _accessControls, ITwistedArtistCommissionRegistry _artistCommissionRegistry) public {
        accessControls = _accessControls;
        artistCommissionRegistry = _artistCommissionRegistry;
    }

    function splitFunds(uint256 _round) external payable isWhitelisted returns (bool) {
        (uint256[] memory _percentages, address payable[] memory _artists) = artistCommissionRegistry.getCommissionSplits();
        require(_percentages.length > 0, "No commissions found");

        uint256 modulo = artistCommissionRegistry.getMaxCommission();

        for (uint256 i = 0; i < _percentages.length; i++) {
            uint256 percentage = _percentages[i];
            address payable artist = _artists[i];

            uint256 valueToSend = msg.value.div(modulo).mul(percentage);
            (bool success, ) = artist.call.value(valueToSend)("");
            require(success, "Transfer failed");
        }

        emit AuctionFundSplit(_round, msg.value, msg.sender);

        return true;
    }
}