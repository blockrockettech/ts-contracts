pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedAccessControls.sol";
import "./interfaces/ITwistedTokenCreator.sol";
import "./splitters/TwistedAuctionFundSplitter.sol";

contract TwistedAuction {
    using SafeMath for uint256;

    event AuctionCreated(
        address indexed _creator
    );

    event BidAccepted(
        uint256 indexed _round,
        uint256 _param,
        uint256 _bidValue,
        address indexed bidder
    );

    uint256 public auctionStartTime;

    uint256 public currentRound;
    uint256 public numOfRounds = 21;
    uint256 public roundLengthInSeconds = 43200;
    uint256 constant public secondsInADay = 86400;

    // round <> parameter from highest bidder
    mapping(uint256 => uint256) winningRoundParameter;

    // round <> highest bid value
    mapping(uint256 => uint256) highestBidFromRound;

    // round <> address of the highest bidder
    mapping(uint256 => address) highestBidderFromRound;

    // round <> whether a TWIST token was successfully minted
    mapping(uint256 => bool) twistMintedForRound;
    //todo: want to ensure that the above and prev round is checked to test eligibility for voting in current round

    ITwistedAccessControls public accessControls;
    ITwistedTokenCreator public twistedTokenCreator;
    TwistedAuctionFundSplitter public auctionFundSplitter;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedAccessControls _accessControls,
                ITwistedTokenCreator _twistedTokenCreator,
                TwistedAuctionFundSplitter _auctionFundSplitter) public {
        accessControls = _accessControls;
        twistedTokenCreator = _twistedTokenCreator;
        auctionFundSplitter = _auctionFundSplitter;
    }

    function _isBidValid(uint256 _bidValue) internal view returns (bool) {
        require(currentRound > 0, "Auction is inactive or not properly configured");

        uint256 offsetFromStartingRound = currentRound.sub(1);

        bool isTwistFromPreviousRoundMinted = true;
        if(offsetFromStartingRound > 0 && !twistMintedForRound[offsetFromStartingRound]) {
            isTwistFromPreviousRoundMinted = false;
        }
        require(isTwistFromPreviousRoundMinted, "TWIST from the previous round has not been minted");

        uint256 currentRoundSecondsOffsetSinceFirstRound = secondsInADay.mul(offsetFromStartingRound);
        uint256 currentRoundStartTime = auctionStartTime.add(currentRoundSecondsOffsetSinceFirstRound);
        uint256 currentRoundEndTime = currentRoundStartTime.add(roundLengthInSeconds);
        bool isWithinBiddingWindow = now >= currentRoundStartTime && now <= currentRoundEndTime;
        require(isWithinBiddingWindow, "This round's bidding window is not open");

        return _bidValue > highestBidFromRound[currentRound];
    }

    // todo: createAuction function to setup rounds etc. needs to be whitelisted
    // todo: issueTwist function
    // todo: bid function
}