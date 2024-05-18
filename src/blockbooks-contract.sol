// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTFactory is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant CONTRACT_FEE = 0.00001 ether;

    struct Collection {
        string name;
        string metadataURI;
        address creator;
        uint256 price;
        bool exists;
        uint id;
    }

    struct Mint {
        uint256 collectionId;
        address ownerOfCollection;
    }

    mapping(uint256 => Collection) public collections;
    mapping(address => uint256[]) public ownerToCollections;
    mapping(address => Mint[]) public addressCollectionIds;
    mapping(uint256 => uint256) private _tokenIdToCollectionId;

    event CollectionCreated(uint256 indexed collectionId, string name, address indexed creator);
    event NFTMinted(uint256 indexed tokenId, uint256 indexed collectionId, address indexed owner);

    constructor() ERC721("BlockBooks Library", "BBL") Ownable(msg.sender) {}

    function createCollection(string memory _name, string memory _metadataUri, uint256 _price) public {
        uint256 newCollectionId = _tokenIds.current();
        collections[newCollectionId] = Collection({
            name: _name,
            metadataURI: _metadataUri,
            creator: msg.sender,
            exists: true,
            id: newCollectionId,
            price: _price
        });
        ownerToCollections[msg.sender].push(newCollectionId);
        _tokenIds.increment();

        emit CollectionCreated(newCollectionId, _name, msg.sender);
    }

    function mintNFT(uint256 _collectionId) public payable {
        require(msg.value > CONTRACT_FEE, "Inssuficient balance to pay the fee");
        require(msg.value > collections[_collectionId].price, "Insufficient price to buy the book");
        require(collections[_collectionId].exists, "Collection does not exist");

        uint256 newTokenId = totalSupply() + 1;
        _mint(msg.sender, newTokenId);
        _tokenIdToCollectionId[newTokenId] = _collectionId; // Map the token ID to the collection ID
        addressCollectionIds[msg.sender].push(Mint(_collectionId, collections[_collectionId].creator));

        payable(collections[_collectionId].creator).transfer(collections[_collectionId].price);
        
        emit NFTMinted(newTokenId, _collectionId, msg.sender);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        uint256 collectionId = _tokenIdToCollectionId[tokenId];
        return collections[collectionId].metadataURI;
    }

    function getAddressCollectionIds() public view returns(Mint[] memory) {
        return addressCollectionIds[msg.sender];
    }

    function getCreatedCollections() public view returns(uint256[] memory) {
        return ownerToCollections[msg.sender];
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}