pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../libs/Strings.sol";
import "../interfaces/erc721/CustomERC721Full.sol";
import "../interfaces/ITwistedTokenCreator.sol";
import "../interfaces/ITwistedAccessControls.sol";


contract TwistedSisterToken is CustomERC721Full, ITwistedTokenCreator {
    using SafeMath for uint256;

    ITwistedAccessControls public accessControls;

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
    uint256 public transfersEnabledFrom;

    mapping(uint256 => Twist) internal twists;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    modifier onlyWhenTokenExists(uint256 _tokenId) {
        require(_exists(_tokenId), "Token not found for ID");
        _;
    }

    constructor (string memory _tokenBaseURI, ITwistedAccessControls _accessControls, uint256 _transfersEnabledFrom)
    public CustomERC721Full("Twisted", "TWIST") {
        accessControls = _accessControls;
        tokenBaseURI = _tokenBaseURI;
        transfersEnabledFrom = _transfersEnabledFrom;
    }

    function createTwisted(
        uint256 _round,
        uint256 _parameter,
        string calldata _ipfsHash,
        address _recipient
    ) external isWhitelisted returns (uint256 _tokenId) {
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
            Strings.strConcat(tokenBaseURI, twist.ipfsHash)
        );
    }

    function tokenURI(uint256 _tokenId) external onlyWhenTokenExists(_tokenId) view returns (string memory) {
        return Strings.strConcat(tokenBaseURI, twists[_tokenId].ipfsHash);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(now > transfersEnabledFrom, "Transfers are currently disabled");
        super.transferFrom(from, to, tokenId);
    }

    //todo: write unit tests
    function updateTransfersEnabledFrom(uint256 _transfersEnabledFrom) external isWhitelisted {
        transfersEnabledFrom = _transfersEnabledFrom;
    }

    function updateTokenBaseURI(string calldata _newBaseURI) external isWhitelisted {
        require(bytes(_newBaseURI).length != 0, "Base URI invalid");
        tokenBaseURI = _newBaseURI;
    }

    function updateIpfsHash(uint256 _tokenId, string calldata _newIpfsHash) external isWhitelisted onlyWhenTokenExists(_tokenId) {
        require(bytes(_newIpfsHash).length != 0, "New IPFS hash invalid");
        twists[_tokenId].ipfsHash = _newIpfsHash;
    }
}
