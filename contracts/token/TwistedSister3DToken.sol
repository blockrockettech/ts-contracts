pragma solidity ^0.5.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/ITwistedSister3DTokenCreator.sol";
import "../interfaces/erc721/CustomERC721Full.sol";
import "../interfaces/ITwistedSisterAccessControls.sol";
import "../TwistedSisterArtistFundSplitter.sol";

contract TwistedSister3DToken is CustomERC721Full, ITwistedSister3DTokenCreator {
    using SafeMath for uint256;

    ITwistedSisterAccessControls public accessControls;
    TwistedSisterArtistFundSplitter public artistFundSplitter;
    CustomERC721Full public twistedSisterToken;

    string public tokenBaseURI = "";
    string public ipfsHash = "";

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor (
        string memory _tokenBaseURI,
        ITwistedSisterAccessControls _accessControls,
        TwistedSisterArtistFundSplitter _artistFundSplitter,
        CustomERC721Full _twistedSisterToken
    ) public CustomERC721Full("twistedsister.io", "TWIST3D") {
        accessControls = _accessControls;
        tokenBaseURI = _tokenBaseURI;
        artistFundSplitter = _artistFundSplitter;
        twistedSisterToken = _twistedSisterToken;
    }

    function createTwistedSister3DToken(
        string calldata _ipfsHash,
        address _recipient
    ) external isWhitelisted returns (uint256 _tokenId) {
        _tokenId = 1;
        ipfsHash = _ipfsHash;
        _mint(_recipient, _tokenId);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked(tokenBaseURI, ipfsHash));
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }

    function transferFrom(address payable from, address to, uint256 _tokenId) public payable {
        super.transferFrom(from, to, _tokenId);

        if (msg.value > 0) {
            uint256 singleUnitOfValue = msg.value.div(100);

            // 20% holders
            uint256 holderSplit = singleUnitOfValue.mul(20);
            _sendValueToTokenHolders(holderSplit);

            // 10% artists
            uint256 artistsSplit = singleUnitOfValue.mul(10);
            (bool fsSuccess, ) = address(artistFundSplitter).call.value(artistsSplit)("");
            require(fsSuccess, "Failed to send funds to the auction fund splitter");

            // 70% seller
            uint256 sellersSplit = singleUnitOfValue.mul(70);
            (bool fromSuccess, ) = from.call.value(sellersSplit)("");
            require(fromSuccess, "Failed to send funds to the seller");
        }
    }

    function _sendValueToTokenHolders(uint256 _value) private {
        uint256 tokenIdPointer = twistedSisterToken.totalSupply();
        uint256 individualTokenHolderSplit = _value.div(tokenIdPointer);
        for(uint i = 1; i <= tokenIdPointer; i++) {
            address payable owner = address(uint160(twistedSisterToken.ownerOf(i)));
            (bool ownerSuccess, ) = owner.call.value(individualTokenHolderSplit)("");
            require(ownerSuccess, "Failed to send funds to a TWIST token owner");
        }
    }

    function updateTokenBaseURI(string calldata _newBaseURI) external isWhitelisted {
        require(bytes(_newBaseURI).length != 0, "Base URI invalid");
        tokenBaseURI = _newBaseURI;
    }

    function updateIpfsHash(string calldata _newIpfsHash) external isWhitelisted {
        require(bytes(_newIpfsHash).length != 0, "New IPFS hash invalid");
        ipfsHash = _newIpfsHash;
    }

    function updateArtistFundSplitter(TwistedSisterArtistFundSplitter _artistFundSplitter) external isWhitelisted {
        artistFundSplitter = _artistFundSplitter;
    }
}