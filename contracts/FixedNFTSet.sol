// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.13;

import "./ERC165.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721TokenReceiver.sol";


// FixedNFTSet manages a fixed amount of non-fungible tokens.
contract FixedNFTSet is ERC721, ERC721Enumerable, ERC165 {

// The number of tokens is fixed during contract creation.
// Zero/absent entries in tokenOwners take the defaultOwner value.
uint256 private immutable tokenCountAndDefaultOwner;

// Each token (index/ID) has one owner at a time.
// Zero/absent entries take the defaultOwner value.
mapping(uint256 => address) private tokenOwners;

// Each token (index/ID) can be granted to a destination address.
mapping(uint256 => address) private tokenApprovals;

// The token-owner:token-operator:approval-flag entries are always true.
mapping(address => mapping(address => bool)) private operatorApprovals;

// Constructor mints n tokens, and transfers each token to the receiver address.
// Token identifiers match their respective index, counting from 0 to n − 1.
// Initial Transfer emission is omitted.
constructor(uint256 n, address receiver) {
	requireAddress(receiver);
	tokenCountAndDefaultOwner = uint(uint160(receiver)) | (n << 160);
}

// RequireAddress denies the zero value.
function requireAddress(address a) internal pure {
	require(a != address(0), "ERC-721 address 0");
}

// RequireToken denies any token index/ID that is not in this contract.
function requireToken(uint256 indexOrID) internal view {
	require(indexOrID < totalSupply(), "ERC-721 token \u2415");
}

function supportsInterface(bytes4 interfaceID) public virtual override(ERC165) pure returns (bool) {
	// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
	return interfaceID == 0x80ac58cd  // ERC721
	    || interfaceID == 0x780e9d63  // ERC721Enumerable
	    || interfaceID == 0x01ffc9a7; // ERC165
}

function totalSupply() public override(ERC721Enumerable) view returns (uint256) {
	return tokenCountAndDefaultOwner >> 160;
}

// Tokens are identified by their index one-to-one.
function tokenByIndex(uint256 index) public override(ERC721Enumerable) view returns (uint256) {
	requireToken(index);
	return index;
}

function tokenOfOwnerByIndex(address owner, uint256 index) public override(ERC721Enumerable) view returns (uint256 tokenID) {
	requireAddress(owner);
	for (tokenID = 0; tokenID < totalSupply(); tokenID++) {
		if (ownerOf(tokenID) == owner) {
			if (index == 0) {
				return tokenID;
			}

			--index;
		}
	}
	revert("ERC-721 index exceeds balance");
}

function balanceOf(address owner) public override(ERC721) view returns (uint256) {
	requireAddress(owner);
	uint256 balance = 0;
	// count owner matches
	for (uint256 tokenID = 0; tokenID < totalSupply(); tokenID++) {
		if (ownerOf(tokenID) == owner) {
			++balance;
		}
	}
	return balance;
}

function ownerOf(uint256 tokenID) public override(ERC721) view returns (address) {
	requireToken(tokenID);
	address owner = tokenOwners[tokenID];
	if (owner == address(0)) {
		return address(uint160(tokenCountAndDefaultOwner));
	}
	return owner;
}

function safeTransferFrom(address from, address to, uint256 tokenID, bytes calldata data) public override(ERC721) payable {
	transferFrom(from, to, tokenID);
	if (msg.sender == tx.origin) { // is contract
		require(ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenID, data) == ERC721TokenReceiver.onERC721Received.selector, "ERC721TokenReceiver mis");
	}
}

function safeTransferFrom(address from, address to, uint256 tokenID) public override(ERC721) payable {
	return this.safeTransferFrom(from, to, tokenID, "");
}

function transferFrom(address from, address to, uint256 tokenID) public override(ERC721) payable {
	address owner = ownerOf(tokenID); // checks token ID
	require(from == owner, "ERC-721 from \u2415");
	requireAddress(to);

	address approved = tokenApprovals[tokenID];
	require(msg.sender == owner || msg.sender == approved || isApprovedForAll(owner, msg.sender), "ERC-721 sender deny");

	// reset approvals from previous owner, if any
	if (approved != address(0)) {
		delete tokenApprovals[tokenID];
		emit Approval(owner, address(0), tokenID);
	}

	// actual transfer
	tokenOwners[tokenID] = to;
	emit Transfer(from, to, tokenID);
}

function approve(address to, uint256 tokenID) public override(ERC721) payable {
	address owner = ownerOf(tokenID); // checks token ID
	require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC-721 sender deny");
	tokenApprovals[tokenID] = to;
	emit Approval(owner, to, tokenID);
}

function setApprovalForAll(address operator, bool approved) public override(ERC721) {
	if (approved) {
		operatorApprovals[msg.sender][operator] = true;
	} else {
		delete operatorApprovals[msg.sender][operator];
	}
	emit ApprovalForAll(msg.sender, operator, approved);
}

function getApproved(uint256 tokenID) public override(ERC721) view returns (address operator) {
	requireToken(tokenID);
	return tokenApprovals[tokenID];
}

function isApprovedForAll(address owner, address operator) public override(ERC721) view returns (bool) {
	return operatorApprovals[owner][operator];
}

}
