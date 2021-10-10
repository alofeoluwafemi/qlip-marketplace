//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract QlipMarketPlace is ERC721URIStorage, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    Counters.Counter public _claimedTokens;
    mapping(uint256 => uint256) private itemIndex;
    mapping(uint256 => uint256) private salePrice;
    mapping(uint256 => NFTDet) public TokenDetails;
    mapping(uint256 => NFTStateMapping) public NFTSTates;
    address public admin;

    //Tracke user owned NFTs
    mapping(address => uint256[]) public userOwnedTokens;
    mapping(uint256 => uint256) public tokenIsAtIndex;

    enum NFTState {
        MINTED,
        ONSALE,
        SOLD,
        ARCHIVED
    }

    struct NFTDet {
        address ownerAddress;
        uint256 _id;
        uint16 _category;
        string tokenURI_;
    }

    struct NFTStateMapping {
        uint256 tokenId;
        NFTState nftState;
    }

    mapping(address => bool) QLIPMinters;
    mapping(uint256 => address) nftOwners;

    NFTDet[] public qlipNFTs;
    NFTStateMapping[] public nftStates;
    NFTDet[] public allTokens;
    address[] NFTClaimers;
    //Mapping value = 1 indicates they have been added to the whitelist, 2 indicates they have claimed
    mapping(address => uint256) whitelistedAddresses;

    event Minted(address minter, string tokenURI, uint256 tokenId);
    event Transfer(address receiver, uint256 tokenId);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        admin = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function whiteListClaimAddress(address[] calldata claimers)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < claimers.length; i++) {
            whitelistedAddresses[claimers[i]] = 1;
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure override returns (bytes4) {
        return (
            bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
        );
    }

    //Function for private sale investors and team to claim the Beningin NFTs
    function claimNFTs(address _nftAddress) public {
        //Start allocating the NFTs from token ID 1-x based on which address claims when
        require(
            whitelistedAddresses[msg.sender] == 1,
            "You are not whitelisted | You have already claimed"
        );
        ERC721 nftAddress = ERC721(_nftAddress);
        _claimedTokens.increment();
        uint256 tokenId = _claimedTokens.current();
        nftAddress.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Transfer(msg.sender, tokenId);
        //Getting the next NFT of type-2
        tokenId = _claimedTokens.current() + 100;
        nftAddress.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Transfer(msg.sender, tokenId);
        //Getting the next NFT of type-3
        tokenId = _claimedTokens.current() + 200;
        nftAddress.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Transfer(msg.sender, tokenId);
    }

    function mintWithIndex(address to, string[] memory tokenURI) public {
        for (uint256 i = 0; i < tokenURI.length; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();

            _mint(to, tokenId);
            _setTokenURI(tokenId, tokenURI[i]);

            //Update user owned tokens
            userOwnedTokens[msg.sender].push(tokenId);
            uint256 arrayLength = userOwnedTokens[msg.sender].length;
            tokenIsAtIndex[tokenId] = arrayLength;

            emit Minted(msg.sender, tokenURI[i], tokenId);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);

        //Remove token in from owned tokens
        uint256 tokenIndex = tokenIsAtIndex[tokenId];
        uint256[] storage owned = userOwnedTokens[from];

        owned[tokenIndex - 1] = owned[owned.length - 1]; //Replace token position with last position
        owned.pop(); //Pop last position to avoid duplicate
    }

    function transferBeningin(
        address receiver,
        uint256[] memory tokenIds,
        address _nftAddress
    ) public onlyAdmin {
        ERC721 nftAddress = ERC721(_nftAddress);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            nftAddress.safeTransferFrom(address(this), receiver, tokenIds[i]);
            emit Transfer(receiver, tokenIds[i]);
        }
    }

    function getAllTokens() public view returns (NFTDet[] memory) {
        return allTokens;
    }

    /*
     * @deprecated
     */
    function __getNftByAddress(address _nftAddress)
        public
        view
        returns (uint256[] memory)
    {
        address userAddress = _nftAddress;
        uint256[] memory userTokens;
        uint256 j = 0;
        for (uint256 i = 0; i < allTokens.length; i++) {
            if (ownerOf(allTokens[i]._id) == userAddress) {
                userTokens[j] = allTokens[i]._id;
                j += 1;
            }
        }

        return userTokens;
    }

    function getNftByAddress(address _nftAddress)
        public
        view
        returns (uint256[] memory)
    {
        return userOwnedTokens[_nftAddress];
    }

    function getNFTState(uint256 tokenId) public view returns (NFTState) {
        return NFTSTates[tokenId].nftState;
    }

    function isQLIPMinted(address owner) public view returns (bool) {
        if (QLIPMinters[owner] == true) {
            return true;
        } else {
            return false;
        }
    }
}
