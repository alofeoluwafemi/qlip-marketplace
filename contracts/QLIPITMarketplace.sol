//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract QLIPITMarketplace is ERC721URIStorage, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
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

    event Minted(address minter, string tokenURI, uint256 tokenId);
    event SetSale(address seller, uint256 tokenId);
    event BuyToken(address seller, address buyer, uint256 tokenId);

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

    function whiteListQLIPMinters(address qlipMinter) public onlyAdmin {
        QLIPMinters[qlipMinter] = true;
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

    function setSale(
        uint256 tokenId,
        uint256 price,
        address _nftAddress
    ) public {
        ERC721 nftAddress = ERC721(_nftAddress);
        address owner = nftAddress.ownerOf(tokenId);
        require(owner != address(0), "setSale: nonexistent token");
        require(msg.sender == owner);

        nftOwners[tokenId] = owner;

        if (NFTSTates[tokenId].tokenId == 0) {
            NFTStateMapping memory nftStateChange = NFTStateMapping(
                tokenId,
                NFTState.ONSALE
            );
            NFTSTates[tokenId] = nftStateChange;
            nftStates.push(nftStateChange);
        } else {
            NFTStateMapping memory nftStateChange = NFTSTates[tokenId];
            nftStateChange.nftState = NFTState.ONSALE;
            NFTSTates[tokenId] = nftStateChange;
        }

        if (TokenDetails[tokenId].ownerAddress == address(0)) {
            TokenDetails[tokenId].ownerAddress = owner;
            TokenDetails[tokenId]._id = tokenId;
            allTokens.push(TokenDetails[tokenId]);
        }
        salePrice[tokenId] = price;
        nftAddress.safeTransferFrom(msg.sender, address(this), tokenId);
        emit SetSale(msg.sender, tokenId);
    }

    function buyTokenOnSale(uint256 tokenId, address _nftAddress)
        public
        payable
    {
        ERC721 nftAddress = ERC721(_nftAddress);

        uint256 price = salePrice[tokenId];
        require(price != 0, "buyToken: price equals 0");
        require(
            msg.value == price,
            "buyToken: price doesn't equal salePrice[tokenId]"
        );
        address payable nftOwner = payable(nftOwners[tokenId]);

        NFTStateMapping memory nftStateChange = NFTSTates[tokenId];
        nftStateChange.nftState = NFTState.SOLD;
        NFTSTates[tokenId] = nftStateChange;

        nftAddress.transferFrom(address(this), msg.sender, tokenId);

        uint256 qlipAmount = (msg.value * 5) / 100;
        uint256 ownerAmount = msg.value - qlipAmount;
        address payable qlipAddress = payable(admin);

        //No royalty here, just flash sale and done!
        qlipAddress.transfer(qlipAmount);
        nftOwner.transfer(ownerAmount);

        salePrice[tokenId] = 0;
        emit BuyToken(nftOwner, msg.sender, tokenId);
    }

    function mintWithIndex(
        address to,
        string memory tokenURI,
        uint16 _category
    ) public {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _mint(to, tokenId);

        TokenDetails[tokenId].ownerAddress = to;
        TokenDetails[tokenId]._id = tokenId;
        TokenDetails[tokenId]._category = _category;
        _setTokenURI(tokenId, tokenURI);

        TokenDetails[tokenId].tokenURI_ = tokenURI;

        NFTStateMapping memory nftStateChange = NFTStateMapping(
            tokenId,
            NFTState.MINTED
        );
        NFTSTates[tokenId] = nftStateChange;
        nftStates.push(nftStateChange);

        if (QLIPMinters[msg.sender] == true) {
            qlipNFTs.push(TokenDetails[tokenId]);
        }

        allTokens.push(TokenDetails[tokenId]);

        //Update user owned tokens
        userOwnedTokens[msg.sender].push(tokenId);
        uint256 arrayLength = userOwnedTokens[msg.sender].length;
        tokenIsAtIndex[tokenId] = arrayLength;

        emit Minted(msg.sender, tokenURI, tokenId);
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

    function getSalePrice(uint256 tokenId) public view returns (uint256) {
        return salePrice[tokenId];
    }

    function __getAllTokenDetails(uint256 tokenId)
        public
        view
        returns (NFTDet memory Details)
    {
        Details.ownerAddress = TokenDetails[tokenId].ownerAddress;
        Details._id = TokenDetails[tokenId]._id;
        Details._category = TokenDetails[tokenId]._category;
        Details.tokenURI_ = TokenDetails[tokenId].tokenURI_;
        //Here, we will set the metadata hash link of the token metadata from Pinata
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
            if (allTokens[i].ownerAddress == userAddress) {
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
