pragma solidity ^0.5.0;

contract ITwistedTokenCreator {
    function createTwisted(
        uint256 _round,
        uint256 _parameter,
        string calldata _ipfsUrl,
        address _owner
    ) external returns (uint256 _tokenId);
}
