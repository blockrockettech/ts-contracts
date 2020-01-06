pragma solidity ^0.5.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BuyNowNFTMarketplace {
    using SafeMath for uint256;

    event Purchase(address indexed _buyer, uint _tokenId, uint256 _priceInWei);
    event Listing(address indexed _seller, uint indexed _tokenId, uint256 _priceInWei);
    event Delisting(address indexed _seller, uint indexed _tokenId);

    modifier onlyWhenTokenOwner(uint256 _tokenId) {
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not the owner of the NFT");
        _;
    }

    modifier onlyWhenMarketplaceIsApproved(uint256 _tokenId) {
        address owner = nft.ownerOf(_tokenId);
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(owner, address(this)), "NFT not approved to sell");
        _;
    }

    IERC721 public nft;

    // Manages all listings
    mapping(uint256 => uint256) internal tokenIdToPrice;
    uint256[] internal listedTokenIds;

    constructor(IERC721 _nft) public {
        nft = _nft;
    }

    function listToken(uint256 _tokenId, uint256 _priceInWei)
    external onlyWhenTokenOwner(_tokenId) onlyWhenMarketplaceIsApproved(_tokenId) returns (bool) {
        require(tokenIdToPrice[_tokenId] == 0, "Must not be already listed");
        require(_priceInWei > 0, "Must have a positive price");

        tokenIdToPrice[_tokenId] = _priceInWei;

        listedTokenIds.push(_tokenId);

        emit Listing(msg.sender, _tokenId, _priceInWei);

        return true;
    }

    function delistToken(uint256 _tokenId) public onlyWhenTokenOwner(_tokenId) returns (bool) {
        delete tokenIdToPrice[_tokenId];

        emit Delisting(msg.sender, _tokenId);

        return true;
    }

    function buyNow(uint256 _tokenId) external payable onlyWhenMarketplaceIsApproved(_tokenId) {
        require(tokenIdToPrice[_tokenId] > 0, "Token not listed");
        require(msg.value >= tokenIdToPrice[_tokenId], "Value is below asking price");

        address tokenSeller = nft.ownerOf(_tokenId);
        nft.transferFrom(tokenSeller, msg.sender, _tokenId);

        delistToken(_tokenId);

        // Refund any change
        if(msg.value > tokenIdToPrice[_tokenId]) {
            uint256 change = msg.value.sub(tokenIdToPrice[_tokenId]);
            (bool changeSuccess, ) = msg.sender.call.value(change)("");
            require(changeSuccess, "Failed to return change to the sender");
        }

        emit Purchase(msg.sender, _tokenId, msg.value);
    }

    function listedTokens() external view returns (uint256[] memory) {
        return listedTokenIds;
    }

    function listedTokenPrice(uint256 _tokenId) external view returns (uint256) {
        return tokenIdToPrice[_tokenId];
    }
}