pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedAccessControls.sol";
import "./interfaces/ITwistedTokenCreator.sol";
import "./interfaces/ITwistedAuctionFundSplitter.sol";

contract TwistedAuction {
    using SafeMath for uint256;

    event AuctionCreated(
        uint256 _numOfRounds,
        uint256 _roundStartTime,
        address indexed _creator
    );

    event BidAccepted(
        uint256 indexed _round,
        uint256 _param,
        uint256 _value,
        address indexed bidder
    );

    bool public isAuctionActive;

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

    ITwistedAccessControls public accessControls;
    ITwistedTokenCreator public twistedTokenCreator;
    ITwistedAuctionFundSplitter public auctionFundSplitter;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedAccessControls _accessControls,
                ITwistedTokenCreator _twistedTokenCreator,
                ITwistedAuctionFundSplitter _auctionFundSplitter) public {
        accessControls = _accessControls;
        twistedTokenCreator = _twistedTokenCreator;
        auctionFundSplitter = _auctionFundSplitter;
    }

    function isRoundOpenForBidding() public view returns (bool) {
        require(isAuctionActive && currentRound > 0, "Auction is inactive or not properly configured");
        uint256 offsetFromStartingRound = currentRound.sub(1);
        uint256 currentRoundSecondsOffsetSinceFirstRound = secondsInADay.mul(offsetFromStartingRound);
        uint256 currentRoundStartTime = auctionStartTime.add(currentRoundSecondsOffsetSinceFirstRound);
        uint256 currentRoundEndTime = currentRoundStartTime.add(roundLengthInSeconds);
        return now >= currentRoundStartTime && now <= currentRoundEndTime;
    }

    // todo: createAuction function to setup rounds etc. needs to be whitelisted
    // todo: issueTwist function
    // todo: bid function
}