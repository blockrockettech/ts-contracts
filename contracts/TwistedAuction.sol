pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedAccessControls.sol";
import "./interfaces/ITwistedTokenCreator.sol";
import "./interfaces/ITwistedAuctionFundSplitter.sol";

contract TwistedAuction {
    using SafeMath for uint256;

    event BidAccepted(
        uint256 indexed _round,
        uint256 _param,
        uint256 _value,
        address indexed bidder
    );

    uint256 public currentRound;

    // round <> parameter from highest bidder
    mapping(uint256 => uint256) winningRoundParameter;

    // round <> highest bid value
    mapping(uint256 => uint256) highestBidFromRound;

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

    // todo: createAuction function to setup rounds etc. needs to be whitelisted
    // todo: issueTwist function
    // todo: bid function
}