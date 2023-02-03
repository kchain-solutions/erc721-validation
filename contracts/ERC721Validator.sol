// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721Validator {
    event Validation(
        string validatorId,
        address nftAddr,
        address userAddr,
        bytes32 verificationHash,
        bool result
    );

    event AddNFT(string validatorId, address NFTAddr, address from);
    event RemoveNFT(string validatorId, address NFTAddr, address from);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    address owner;
    bool public isActive;
    address[] public nfts;
    string validatorId;

    mapping(address => bytes32) private userSecrets;

    constructor(string memory _validatorId) {
        owner = msg.sender;
        isActive = true;
        validatorId = _validatorId;
    }

    function setSecret(bytes32 _secret) public {
        userSecrets[msg.sender] = _secret;
    }

    function validate(string memory _userSessionId) public {
        require(nfts.length > 0, "Empty NFT collection");
        require(
            userSecrets[msg.sender] != bytes32(0),
            "userSecret not initialized"
        );
        bool found = false;
        uint balance = 0;
        address nft = address(0x0);
        uint i = 0;
        for (i = 0; i < nfts.length; i++) {
            balance = 0;
            IERC721 ierc721 = IERC721(nfts[i]);
            balance = ierc721.balanceOf(msg.sender);
            if (balance > 0) {
                found = true;
                nft = nfts[i];
                break;
            }
        }
        bytes32 verificationHash = keccak256(
            abi.encode(_userSessionId, userSecrets[msg.sender])
        );
        emit Validation(validatorId, nft, msg.sender, verificationHash, found);
    }

    function getNFTs() public view returns (address[] memory) {
        return nfts;
    }

    function addNFT(address _nftAddr) public onlyOwner {
        nfts.push(_nftAddr);
        emit AddNFT(validatorId, _nftAddr, msg.sender);
    }

    function removeNFT(address _nftAddr) public onlyOwner {
        uint newLength = 0;
        bool found = false;
        for (uint idx = 0; idx < nfts.length; idx++) {
            if (nfts[idx] != _nftAddr) {
                nfts[newLength] = nfts[idx];
                newLength++;
            } else found = true;
        }
        nfts.pop();
        emit RemoveNFT(validatorId, _nftAddr, msg.sender);
    }

    function activate() public onlyOwner {
        isActive = true;
    }

    function deactivate() public onlyOwner {
        isActive = false;
    }
}
