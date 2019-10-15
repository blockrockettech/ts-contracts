pragma solidity ^0.5.0;

import "../TwistedAuction.sol";

contract TwistedAuctionMock is TwistedAuction {
    constructor(
        ITwistedAccessControls _accessControls,
        ITwistedTokenCreator _twistedTokenCreator,
        TwistedAuctionFundSplitter _auctionFundSplitter,
        address payable _printingFund,
        address payable _auctionOwner,
        uint256 _auctionStartTime
    ) public TwistedAuction(_accessControls, _twistedTokenCreator, _auctionFundSplitter, _printingFund, _auctionOwner, _auctionStartTime) {}

    function updateAuctionStartTime(uint256 _auctionStartTime) external isWhitelisted {
        auctionStartTime = _auctionStartTime;
    }

    function updateCurrentRound(uint256 _currentRound) external isWhitelisted {
        currentRound = _currentRound;
    }
}
