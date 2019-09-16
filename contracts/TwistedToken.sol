pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "./ERC721/CustomERC721Full.sol";

import "./libs/Strings.sol";
import "./interfaces/ITwistedTokenCreator.sol";

contract TwistedToken is CustomERC721Full, WhitelistedRole, ITwistedTokenCreator {
    using SafeMath for uint256;

    string public tokenBaseURI = "";

    event TwistMinted(
        address indexed _recipient,
        uint256 indexed _tokenId
    );

    struct Twist {
        uint256 round;
        uint256 parameter;
        string ipfsHash;
    }

    uint256 public tokenIdPointer = 0;

    address public auction;
    mapping(uint256 => Twist) internal twists;

    modifier onlyWhenTokenExists(uint256 _tokenId) {
        require(_exists(_tokenId), "Token not found for ID");
        _;
    }

    constructor (string memory _tokenBaseURI, address _auction) public CustomERC721Full("Twisted", "TWIST") {
        super.addWhitelisted(msg.sender);
        super.addWhitelisted(_auction);
        tokenBaseURI = _tokenBaseURI;
        auction = _auction;
    }

    function createTwisted(
        uint256 _round,
        uint256 _parameter,
        string calldata _ipfsHash,
        address _recipient
    ) external onlyWhitelisted returns (uint256 _tokenId) {
        tokenIdPointer = tokenIdPointer.add(1);
        uint256 tokenId = tokenIdPointer;

        // Create Twist metadata
        twists[tokenId] = Twist({
            round: _round,
            parameter: _parameter,
            ipfsHash: _ipfsHash
        });

        _mint(_recipient, tokenId);

        emit TwistMinted(_recipient, tokenId);

        return tokenId;
    }

    function attributes(uint256 _tokenId) external onlyWhenTokenExists(_tokenId) view returns (
        uint256 _round,
        uint256 _parameter,
        string memory _ipfsUrl
    ) {
        Twist storage twist = twists[_tokenId];
        return (
            twist.round,
            twist.parameter,
            Strings.strConcat(tokenBaseURI, twists[_tokenId].ipfsHash)
        );
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 _tokenId) external onlyWhenTokenExists(_tokenId) view returns (string memory) {
        return Strings.strConcat(tokenBaseURI, twists[_tokenId].ipfsHash);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function updateTokenBaseURI(string calldata _newBaseURI) external onlyWhitelisted {
        require(bytes(_newBaseURI).length != 0, "Base URI invalid");
        tokenBaseURI = _newBaseURI;
    }

    function updateIpfsHash(uint256 _tokenId, string calldata _newIpfsHash) external onlyWhitelisted onlyWhenTokenExists(_tokenId) {
        require(bytes(_newIpfsHash).length != 0, "New IPFS hash invalid");
        twists[_tokenId].ipfsHash = _newIpfsHash;
    }

    function updateAuctionWhitelist(address _to) external onlyWhitelisted {
        require(msg.sender != auction, "Only whitelisted owners can update the auction's whitelisted address");
        super.removeWhitelisted(auction);
        super.addWhitelisted(_to);
        auction = _to;
    }
}
