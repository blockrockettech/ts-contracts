pragma solidity ^0.5.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedSisterAccessControls.sol";
import "./interfaces/ITwistedSister3DTokenCreator.sol";
import "./interfaces/erc721/CustomERC721Full.sol";
import "./TwistedSisterArtistFundSplitter.sol";

contract TwistedSisterAuction {
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

    uint256 public startTime;
    uint256 public endTime;

    // round <> highest bid value
    mapping(uint256 => uint256) public highestBidFromRound;

    // round <> address of the highest bidder
    mapping(uint256 => address) public highestBidderFromRound;

    ITwistedSisterAccessControls public accessControls;
    ITwistedSister3DTokenCreator public twisted3DTokenCreator;
    TwistedSisterArtistFundSplitter public artistFundSplitter;
    CustomERC721Full public twistedSisterToken;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedSisterAccessControls _accessControls,
                ITwistedSister3DTokenCreator _twisted3DTokenCreator,
                TwistedSisterArtistFundSplitter _artistFundSplitter,
                CustomERC721Full _twistedSisterToken,
                uint256 _startTime,
                uint256 _endTime) public {
        accessControls = _accessControls;
        twisted3DTokenCreator = _twisted3DTokenCreator;
        artistFundSplitter = _artistFundSplitter;
        twistedSisterToken = _twistedSisterToken;
        startTime = _startTime;
        endTime = _endTime;
    }

    function _isWithinBiddingWindowForRound() internal view returns (bool) {
        return now >= startTime && now <= endTime;
    }

    function _isBidValid(uint256 _bidValue) internal view {
        require(currentRound <= numOfRounds, "Auction has ended");
        require(_bidValue >= minBid, "The bid didn't reach the minimum bid threshold");
        require(_bidValue >= highestBidFromRound[currentRound].add(minBid), "The bid was not higher than the last");
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

    function _splitFundsFromHighestBid(uint256 _value) private {
        uint256 singleUnitOfValue = _value.div(100);

        // Split - 90% -> 21 Twist owners, 10% -> TwistedArtistFundSplitter
        uint256 twistHoldersSplit = singleUnitOfValue.mul(90);
        _sendFundsToTwistHolders(twistHoldersSplit);

        uint256 artistSplit = singleUnitOfValue.mul(10);
        (bool fsSuccess, ) = address(artistFundSplitter).call.value(artistSplit)("");
        require(fsSuccess, "Failed to send funds to the artist fund splitter");
    }

    function _sendFundsToTwistHolders(uint256 _value) private {
        uint256 tokenIdPointer = twistedSisterToken.totalSupply();
        uint256 individualTokenHolderSplit = _value.div(tokenIdPointer);
        for(uint i = 1; i <= tokenIdPointer; i++) {
            address payable owner = address(uint160(twistedSisterToken.ownerOf(i)));
            (bool ownerSuccess, ) = owner.call.value(individualTokenHolderSplit)("");
            require(ownerSuccess, "Failed to send funds to a TWIST token owner");
        }
    }

    function bid(uint256 _parameter) external payable {
        require(_parameter > 0, "The parameter cannot be zero");
        _isBidValid(msg.value);
        _refundHighestBidder();
        highestBidFromRound[currentRound] = msg.value;
        highestBidderFromRound[currentRound] = msg.sender;
        emit BidAccepted(currentRound, now, winningRoundParameter[currentRound], highestBidFromRound[currentRound], highestBidderFromRound[currentRound]);
    }

    function issueTwistAndPrepNextRound(string calldata _ipfsHash) external {
        //todo: is this require required?
        //require(!_isWithinBiddingWindowForRound(), "Current round still active");

        //uint256 previousRound = currentRound;
        //currentRound = currentRound.add(1);

        // Handle no-bid scenario
//        if (highestBidderFromRound[previousRound] == address(0)) {
//            highestBidderFromRound[previousRound] = auctionOwner;
//            winningRoundParameter[previousRound] = 1; // 1 is the default and first param (1...64)
//        }

        // Issue the TWIST3D
        //address winner = highestBidderFromRound[previousRound];
        //uint256 winningRoundParam = winningRoundParameter[previousRound];

        uint256 tokenId = twisted3DTokenCreator.createTwistedSister3DToken(_ipfsHash, winner);
        require(tokenId == 1, "Error minting the TWIST3D token");

        // Take the proceedings from the highest bid and split funds accordingly
        //_splitFundsFromHighestBid();

        //emit RoundFinalised(previousRound, now, winningRoundParam, highestBidFromRound[previousRound], winner);
    }

    function updateAuctionStartTime(uint256 _startTime) external isWhitelisted {
        startTime = _startTime;
    }

    function updateEndTime(uint256 _endTime) external isWhitelisted {
        endTime = _endTime;
    }

    function updateArtistFundSplitter(TwistedSisterArtistFundSplitter _artistFundSplitter) external isWhitelisted {
        artistFundSplitter = _artistFundSplitter;
    }
}
