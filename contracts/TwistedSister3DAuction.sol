pragma solidity ^0.5.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./interfaces/ITwistedSisterAccessControls.sol";
import "./interfaces/ITwistedSister3DTokenCreator.sol";
import "./interfaces/erc721/CustomERC721Full.sol";
import "./TwistedSisterArtistFundSplitter.sol";

contract TwistedSister3DAuction {
    using SafeMath for uint256;

    event TWIST3DIssued(
        address indexed _buyer,
        uint256 _value
    );

    uint256 public highestPayment;
    address public buyer;

    ITwistedSisterAccessControls public accessControls;
    ITwistedSister3DTokenCreator public twisted3DTokenCreator;
    TwistedSisterArtistFundSplitter public artistFundSplitter;
    CustomERC721Full public twistedSisterToken;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedSisterAccessControls _accessControls,
                ITwistedSister3DTokenCreator _twisted3DTokenCreator,
                TwistedSisterArtistFundSplitter _artistFundSplitter,
                CustomERC721Full _twistedSisterToken
    ) public {
        accessControls = _accessControls;
        twisted3DTokenCreator = _twisted3DTokenCreator;
        artistFundSplitter = _artistFundSplitter;
        twistedSisterToken = _twistedSisterToken;
    }

    function() external payable {
        if (msg.value > highestPayment) {
            highestPayment = msg.value;
            buyer = msg.sender;
        }
    }

    function issue3DTwistToken(string calldata _ipfsHash) external isWhitelisted {
        require(buyer != address(0));

        // Issue the TWIST3D
        uint256 tokenId = twisted3DTokenCreator.createTwistedSister3DToken(_ipfsHash, buyer);
        require(tokenId == 1, "Error minting the TWIST3D token");

        // Take the funds paid by the buyer and split it between the TWIST token holders and artist
        uint256 valueSent = _splitFundsFromPayment();

        emit TWIST3DIssued(buyer, valueSent);
    }

    function _splitFundsFromPayment() private returns(uint256) {
        uint256 balance = address(this).balance;
        uint256 singleUnitOfValue = balance.div(100);

        // Split - 90% -> 21 Twist owners, 10% -> TwistedArtistFundSplitter
        uint256 twistHoldersSplit = singleUnitOfValue.mul(90);
        _sendFundsToTwistHolders(twistHoldersSplit);

        uint256 artistSplit = singleUnitOfValue.mul(10);
        (bool fsSuccess, ) = address(artistFundSplitter).call.value(artistSplit)("");
        require(fsSuccess, "Failed to send funds to the artist fund splitter");

        return balance;
    }

    function _sendFundsToTwistHolders(uint256 _value) private {
        uint256 tokenIdPointer = twistedSisterToken.totalSupply();
        uint256 individualTokenHolderSplit = _value.div(tokenIdPointer);
        for(uint i = 1; i <= tokenIdPointer; i++) {
            address payable owner = address(uint160(twistedSisterToken.ownerOf(i)));
            (bool ownerSuccess, ) = owner.call.value(individualTokenHolderSplit)("");
            require(ownerSuccess, "Failed to send funds to a TWIST token owner");
        }
    }

    function withdrawAllFunds() external isWhitelisted {
        /* solium-disable-next-line */
        (bool success,) = msg.sender.call.value(address(this).balance)("");
        require(success, "Failed to withdraw contract funds");
    }

    function updateBuyer(address _buyer) external isWhitelisted {
        buyer = _buyer;
    }

    function updateArtistFundSplitter(TwistedSisterArtistFundSplitter _artistFundSplitter) external isWhitelisted {
        artistFundSplitter = _artistFundSplitter;
    }
}
