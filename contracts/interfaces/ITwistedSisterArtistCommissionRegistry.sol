pragma solidity ^0.5.12;

contract ITwistedSisterArtistCommissionRegistry {
    function getCommissionSplits() external view returns (uint256[] memory _percentages, address payable[] memory _artists);
    function getMaxCommission() external view returns (uint256);
}
