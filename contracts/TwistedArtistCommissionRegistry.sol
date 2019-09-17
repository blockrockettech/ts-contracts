pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedArtistCommissionRegistry.sol";

contract TwistedArtistCommissionRegistry{
    struct CommissionSplit {
        uint256 percentage;
        address payable recipient;
    }
}