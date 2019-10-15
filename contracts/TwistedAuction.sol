pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedAccessControls.sol";
import "./interfaces/ITwistedTokenCreator.sol";
import "./splitters/TwistedAuctionFundSplitter.sol";

contract TwistedAuction {
    using SafeMath for uint256;

    event BidAccepted(
        uint256 indexed _round,
        uint256 _timeStamp,
        uint256 _param,
        uint256 _amount,
        address indexed _bidder
    );

    event BidderRefunded(
        uint256 indexed _round,
        uint256 _amount,
        address indexed _bidder
    );

    event RoundFinalised(
        uint256 indexed _round,
        uint256 _timestamp,
        uint256 _param,
        uint256 _highestBid,
        address _highestBidder
    );

    address payable printingFund;
    address payable auctionOwner;

    uint256 public auctionStartTime;

    uint256 public minBid = 0.02 ether;
    uint256 public currentRound = 1;
    uint256 public numOfRounds = 21;
    uint256 public roundLengthInSeconds = 0.5 days;
    uint256 constant public secondsInADay = 1 days;

    // round <> parameter from highest bidder
    mapping(uint256 => uint256) public winningRoundParameter;

    // round <> highest bid value
    mapping(uint256 => uint256) public highestBidFromRound;

    // round <> address of the highest bidder
    mapping(uint256 => address) public highestBidderFromRound;

    ITwistedAccessControls public accessControls;
    ITwistedTokenCreator public twistedTokenCreator;
    TwistedAuctionFundSplitter public auctionFundSplitter;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedAccessControls _accessControls,
                ITwistedTokenCreator _twistedTokenCreator,
                TwistedAuctionFundSplitter _auctionFundSplitter,
                address payable _printingFund,
                uint256 _auctionStartTime) public {
        require(now < _auctionStartTime, "Auction start time is not in the future");
        accessControls = _accessControls;
        twistedTokenCreator = _twistedTokenCreator;
        auctionFundSplitter = _auctionFundSplitter;
        printingFund = _printingFund;
        auctionStartTime = _auctionStartTime;
        auctionOwner = msg.sender;
    }

    function _isWithinBiddingWindowForRound() internal view returns (bool) {
        uint256 offsetFromStartingRound = currentRound.sub(1);
        uint256 currentRoundSecondsOffsetSinceFirstRound = secondsInADay.mul(offsetFromStartingRound);
        uint256 currentRoundStartTime = auctionStartTime.add(currentRoundSecondsOffsetSinceFirstRound);
        uint256 currentRoundEndTime = currentRoundStartTime.add(roundLengthInSeconds);
        return now >= currentRoundStartTime && now <= currentRoundEndTime;
    }

    function _isBidValid(uint256 _bidValue) internal view {
        require(currentRound <= numOfRounds, "Auction has ended");
        require(_bidValue >= minBid, "The bid didn't reach the minimum bid threshold");
        require(_bidValue > highestBidFromRound[currentRound].add(minBid), "The bid was not higher than the last");
        require(_isWithinBiddingWindowForRound(), "This round's bidding window is not open");
    }

    function _refundHighestBidder() internal {
        uint256 highestBidAmount = highestBidFromRound[currentRound];
        if (highestBidAmount > 0) {
            address highestBidder = highestBidderFromRound[currentRound];

            // Clear out highest bidder as there is no longer one
            delete highestBidderFromRound[currentRound];

            (bool success, ) = highestBidder.call.value(highestBidAmount)("");
            require(success, "Failed to refund the highest bidder");

            emit BidderRefunded(currentRound, highestBidAmount, highestBidder);
        }
    }

    function _splitFundsFromHighestBid() internal {
        // Split - 50% -> 3D Printing Fund, 50% -> TwistedAuctionFundSplitter
        uint256 valueToSend = highestBidFromRound[currentRound.sub(1)].div(2);

        (bool pfSuccess, ) = printingFund.call.value(valueToSend)("");
        require(pfSuccess, "Failed to transfer funds to the printing fund");

        (bool fsSuccess, ) = address(auctionFundSplitter).call.value(valueToSend)("");
        require(fsSuccess, "Failed to send funds to the auction fund splitter");
    }

    function bid(uint256 _parameter) external payable {
        _isBidValid(msg.value);
        _refundHighestBidder();
        highestBidFromRound[currentRound] = msg.value;
        highestBidderFromRound[currentRound] = msg.sender;
        winningRoundParameter[currentRound] = _parameter;
        emit BidAccepted(currentRound, now, winningRoundParameter[currentRound], highestBidFromRound[currentRound], highestBidderFromRound[currentRound]);
    }

    function issueTwistAndPrepNextRound(string calldata _ipfsHash) external isWhitelisted {
        require(!_isWithinBiddingWindowForRound(), "Current round still active");

        uint256 previousRound = currentRound;
        currentRound = currentRound.add(1);

        // Issue the TWIST
        if (highestBidderFromRound[previousRound] == address(0)) {
            highestBidderFromRound[previousRound] = auctionOwner;
        }

        address winner = highestBidderFromRound[previousRound];
        uint256 winningRoundParam = winningRoundParameter[previousRound];
        uint256 tokenId = twistedTokenCreator.createTwisted(previousRound, winningRoundParam, _ipfsHash, winner);
        require(tokenId == previousRound, "Error minting the TWIST token");

        // Take the proceedings from the highest bid and split funds accordingly
        _splitFundsFromHighestBid();

        emit RoundFinalised(previousRound, now, winningRoundParam, highestBidFromRound[previousRound], winner);
    }

    function updateNumberOfRounds(uint256 _numOfRounds) external isWhitelisted {
        require(_numOfRounds >= currentRound, "Number of rounds can't be smaller than the number of previous");
        numOfRounds = _numOfRounds;
    }

    function updateRoundLength(uint256 _roundLengthInSeconds) external isWhitelisted {
        require(_roundLengthInSeconds < secondsInADay);
        roundLengthInSeconds = _roundLengthInSeconds;
    }
}
