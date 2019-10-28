pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/ITwistedSisterArtistCommissionRegistry.sol";
import "../interfaces/ITwistedSisterArtistCommissionRegistry.sol";

contract TwistedSisterAuctionFundSplitter {
    using SafeMath for uint256;

    event FundSplitAndTransferred(uint256 _totalValue, address payable _recipient);

    ITwistedSisterArtistCommissionRegistry public artistCommissionRegistry;

    constructor(ITwistedSisterArtistCommissionRegistry _artistCommissionRegistry) public {
        artistCommissionRegistry = _artistCommissionRegistry;
    }

    function() external payable {
        (uint256[] memory _percentages, address payable[] memory _artists) = artistCommissionRegistry.getCommissionSplits();
        require(_percentages.length > 0, "No commissions found");

        uint256 modulo = artistCommissionRegistry.getMaxCommission();

        for (uint256 i = 0; i < _percentages.length; i++) {
            uint256 percentage = _percentages[i];
            address payable artist = _artists[i];

            uint256 valueToSend = msg.value.div(modulo).mul(percentage);
            (bool success, ) = artist.call.value(valueToSend)("");
            require(success, "Transfer failed");

            emit FundSplitAndTransferred(valueToSend, artist);
        }
    }
}
