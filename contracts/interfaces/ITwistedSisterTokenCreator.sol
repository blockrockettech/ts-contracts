pragma solidity ^0.5.0;

contract ITwistedSisterTokenCreator {
    function createTwisted(
        uint256 _round,
        uint256 _parameter,
        string calldata _ipfsHash,
        address _recipient
    ) external returns (uint256 _tokenId);
}