pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";

import "./interfaces/ITwistedAuctionFundSplitter.sol";

//todo: This is a work in progress and is moving over to using the artist commission registry
contract TwistedAuctionFundSplitter is ITwistedAuctionFundSplitter, WhitelistedRole {
    using SafeMath for uint256;

    address payable[] public artists;
    address public auction;

    constructor(address payable[] memory _artists, address _auction) public {
        super.addWhitelisted(msg.sender);
        super.addWhitelisted(_auction);
        artists = _artists;
        auction = _auction;
    }

    function splitFunds() external payable onlyWhitelisted returns (bool) {
        return false;
    }
}