// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFTMarketplace {
    using SafeMath for uint256;

// keep track of token Ids
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    struct NFTOffer {
        address seller;
        uint256 price;
        bool isAvailable;
    }

    mapping(uint256 => NFTOffer) public offers;
    mapping(address => uint256[]) public userTokens;

    event NFTOffered(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTPurchased(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);

    ERC721 public nftContract;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() ERC721("NFTMarketplace", "NFTM") {
        owner = msg.sender;
    }

    // Mint new NFTs
    function mintNFT(address to, uint256 tokenId) external onlyOwner {
        nftContract.mint(to, tokenId);
    }

    // Add NFT to the marketplace
    function listNFT(uint256 _tokenId, uint256 _price) external {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Only the owner can offer the NFT");
        require(!offers[_tokenId].isAvailable, "NFT is already offered");

        offers[_tokenId] = NFTOffer(msg.sender, _price, true);
        userTokens[msg.sender].push(_tokenId);

        emit NFTOffered(_tokenId, msg.sender, _price);
    }

    // Buy NFT
    function purchaseNFT(uint256 _tokenId) external payable {
        NFTOffer memory offer = offers[_tokenId];
        require(offer.isAvailable, "NFT is not offered for sale");
        require(msg.value >= offer.price, "Insufficient funds");

        address seller = offer.seller;
        offers[_tokenId] = NFTOffer(address(0), 0, false);
        nftContract.safeTransferFrom(seller, msg.sender, _tokenId);

        payable(seller).transfer(msg.value);

        emit NFTPurchased(_tokenId, seller, msg.sender, offer.price);
    }

    // See NFTs on offer
    function getOffer(uint256 _tokenId) external view returns (address, uint256, bool) {
        NFTOffer memory offer = offers[_tokenId];
        return (offer.seller, offer.price, offer.isAvailable);
    }

    // See your offered NFTs
    function getMyOfferedTokens() external view returns (uint256[] memory) {
        return userTokens[msg.sender];
    }
}
