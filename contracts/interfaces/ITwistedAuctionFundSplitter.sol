pragma solidity ^0.5.0;

contract ITwistedAuctionFundSplitter {
    function splitFunds(uint256 _round) external payable returns (bool);
}