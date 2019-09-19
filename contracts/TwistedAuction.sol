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

    address payable printingFund;

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

    function _resetAuction() internal {
        for(uint256 i = 0; i < numOfRounds; i++) {
            delete winningRoundParameter[i];
            delete highestBidFromRound[i];
            delete highestBidderFromRound[i];
            delete twistMintedForRound[i];
        }
    }

    function _isBidValid(uint256 _bidValue) internal view returns (bool) {
        require(currentRound > 0 && currentRound <= numOfRounds, "Auction is inactive or has ended");

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

    function createAuction(address payable _printingFund, uint256 _auctionStartTime) external isWhitelisted {
        require(now < _auctionStartTime, "Auction start time is not in the future");
        _resetAuction();
        printingFund = _printingFund;
        auctionStartTime = _auctionStartTime;
        currentRound = 1;
        emit AuctionCreated(msg.sender);
    }

    function bid(uint256 _parameter) external payable {
        require(_isBidValid(msg.value), "Bid was unsuccessful");
        // todo: refund the previous highest bid if one exists
        highestBidFromRound[currentRound] = msg.value;
        highestBidderFromRound[currentRound] = msg.sender;
        winningRoundParameter[currentRound] = _parameter;
    }

    function issueTwistAndPrepNextRound(string calldata _ipfsHash) external isWhitelisted {
        uint256 winningRoundParam = winningRoundParameter[currentRound];
        require(winningRoundParam > 0, "No one has bid");
        require(!twistMintedForRound[currentRound], "TWIST token has already minted for the current round");

        // Issue the TWIST
        address winner = highestBidderFromRound[currentRound];
        uint256 tokenId = twistedTokenCreator.createTwisted(currentRound, winningRoundParam, _ipfsHash, winner);
        require(tokenId == currentRound, "Error minting the TWIST token");
        twistMintedForRound[currentRound] = true;

        // todo: Fund split from highest bid

        currentRound.add(1);
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