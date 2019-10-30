pragma solidity ^0.5.5;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721MetadataWithoutTokenURI.sol";

/**
 * @title Custom version of the Full ERC721 Token contract produced by OpenZeppelin
 * This implementation includes all the required, some optional functionality of the ERC721 standard and removes
 * tokenURIs from the base ERC721Metadata contract.
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract CustomERC721Full is ERC721, ERC721Enumerable, ERC721MetadataWithoutTokenURI {
    constructor (string memory name, string memory symbol) public ERC721MetadataWithoutTokenURI(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}
