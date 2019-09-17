pragma solidity ^0.5.0;

contract ITwistedArtistCommissionRegistry {
    function getCommissionSplits() public view returns (uint256[] memory _percentages, address payable[] memory _recipients);
}