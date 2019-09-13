pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";

import "./libs/Strings.sol";
import "./erc721/CustomERC721Full.sol";
import "./interfaces/ITwistedTokenCreator.sol";

contract TwistedToken is CustomERC721Full, WhitelistedRole, ITwistedTokenCreator {
    using SafeMath for uint256;

    string public tokenBaseURI = "";

    event TwistMinted(
        address indexed _to,
        uint256 indexed _tokenId
    );

    struct Twist {
        uint256 round;
        uint256 parameter;
        string ipfsUrl;
    }

    uint256 public tokenIdPointer = 0;
    uint256 public maxSupply = 21;

    mapping(uint256 => Twist) internal twists;

    constructor (string memory _tokenBaseURI, address _auction) public CustomERC721Full("Twisted", "TWIST") {
        super.addWhitelisted(msg.sender);
        super.addWhitelisted(_auction);
        tokenBaseURI = _tokenBaseURI;
    }

    function createTwisted(
        uint256 _round,
        uint256 _parameter,
        string calldata _ipfsUrl,
        address _owner
    ) external onlyWhitelisted returns (uint256 _tokenId) {
        uint256 tokenId = tokenIdPointer.add(1);

        require(tokenId <= maxSupply, "Cannot exceed max supply (21)");

        // reset token pointer
        tokenIdPointer = tokenId;

        // create Twist
        twists[tokenId] = Twist({
            round: _round,
            parameter: _parameter,
            ipfsUrl: _ipfsUrl
        });

        _mint(_owner, tokenId);

        emit TwistMinted(_owner, tokenId);

        return tokenId;
    }

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return Strings.strConcat(tokenBaseURI, Strings.uint2str(tokenId));
    }

    function attributes(uint256 _tokenId) public view returns (
        uint256 _round,
        uint256 _parameter,
        string memory _ipfsUrl
    ) {
        require(_exists(_tokenId), "Token ID not found");
        Twist storage twist = twists[_tokenId];
        return (
            twist.round,
            twist.parameter,
            twist.ipfsUrl
        );
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function updateTokenBaseURI(string memory _newBaseURI) public onlyWhitelisted {
        require(bytes(_newBaseURI).length != 0, "Base URI invalid");
        tokenBaseURI = _newBaseURI;
    }

    function updateIpfsUrl(uint256 _tokenId, string memory _newIpfsUrl) public onlyWhitelisted {
        require(bytes(_newIpfsUrl).length != 0, "New IPFS URL invalid");
        require(_exists(_tokenId), "Token ID not found");
        twists[_tokenId].ipfsUrl = _newIpfsUrl;
    }

    // todo: think about burn and updating auction address
}
