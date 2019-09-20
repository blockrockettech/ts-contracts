pragma solidity ^0.5.0;

import "../TwistedAuction.sol";

contract TwistedAuctionMock is TwistedAuction {
    constructor(ITwistedAccessControls _accessControls,
        ITwistedTokenCreator _twistedTokenCreator,
        TwistedAuctionFundSplitter _auctionFundSplitter)
        public TwistedAuction(_accessControls, _twistedTokenCreator, _auctionFundSplitter) {}

    function updateAuctionStartTime(uint256 _auctionStartTime) external isWhitelisted {
        auctionStartTime = _auctionStartTime;
    }
}