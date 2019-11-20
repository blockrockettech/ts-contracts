pragma solidity ^0.5.12;

contract ITwistedSister3DTokenCreator {
    function createTwistedSister3DToken(
        string calldata _ipfsHash,
        address _recipient
    ) external returns (uint256 _tokenId);
}
