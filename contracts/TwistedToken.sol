pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";

import "./libs/Strings.sol";
import "./interfaces/ITwistedTokenCreator.sol";

contract TwistedToken is ERC721Full, WhitelistedRole, ITwistedTokenCreator {
    using SafeMath for uint256;

    string public tokenBaseURI = "";

    event TwistMinted(
        address indexed _recipient,
        uint256 indexed _tokenId
    );

    struct Twist {
        uint256 round;
        uint256 parameter;
    }

    uint256 public tokenIdPointer = 0;

    address public auction;
    mapping(uint256 => Twist) internal twists;

    constructor (string memory _tokenBaseURI, address _auction) public ERC721Full("Twisted", "TWIST") {
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
            parameter: _parameter
        });

        _mint(_recipient, tokenId);
        _setTokenURI(tokenId, Strings.strConcat(tokenBaseURI, _ipfsHash));

        emit TwistMinted(_recipient, tokenId);

        return tokenId;
    }

    function attributes(uint256 _tokenId) external view returns (
        uint256 _round,
        uint256 _parameter
    ) {
        require(_exists(_tokenId), "Token not found for ID");
        Twist storage twist = twists[_tokenId];
        return (
            twist.round,
            twist.parameter
        );
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function updateTokenBaseURI(string calldata _newBaseURI) external onlyWhitelisted {
        require(bytes(_newBaseURI).length != 0, "Base URI invalid");
        tokenBaseURI = _newBaseURI;
    }

    function updateIpfsUrlWithHash(uint256 _tokenId, string calldata _newIpfsHash) external onlyWhitelisted {
        require(bytes(_newIpfsHash).length != 0, "New IPFS hash invalid");
        _setTokenURI(_tokenId, Strings.strConcat(tokenBaseURI, _newIpfsHash));
    }

    function updateAuctionWhitelist(address _to) external onlyWhitelisted {
        require(msg.sender != auction, "Only whitelisted owners can update the auction's whitelisted address");
        super.removeWhitelisted(auction);
        super.addWhitelisted(_to);
        auction = _to;
    }
}
