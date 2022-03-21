// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

import "./ERC165.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721TokenReceiver.sol";


// FixedNFTSet manages a fixed amount of NFTs.
contract FixedNFTSet is ERC721, ERC721Enumerable, ERC165 {

// The number of tokens is fixed during contract creation.
uint private immutable tokenCount;

// Each token (ID/index) has one owner at a time.
// Zero/absent entries default to defaultOwner.
mapping(uint => address) private tokenOwners;

// Zero/absent entries in tokenOwners default to defaultOwner.
address private immutable defaultOwner;

// Each token (ID/index) can [optional] grant transfer permission to one operator.
mapping(uint => address) private tokenApprovals;

// The token-owner:token-operator:approval-flag leaks by design.
mapping(address => mapping(address => bool)) private operatorApprovals;

// Constructor mints n tokens with ID 0 to n, excluding n.
// Each token is assined to owner.
constructor(uint n, address owner) {
	requireAddress(owner);
	tokenCount   = n;
	defaultOwner = owner;
}

function requireAddress(address a) private pure {
	require(a != address(0), "ERC721 address 0");
}

function requireToken(uint indexOrID) private view {
	require(indexOrID < tokenCount, "ERC-721 token \u2415");
}

function supportsInterface(bytes4 interfaceID) public virtual override(ERC165) pure returns (bool) {
	// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
	return interfaceID == 0x80ac58cd  // ERC721
	    || interfaceID == 0x780e9d63  // ERC721Enumerable
	    || interfaceID == 0x01ffc9a7; // ERC165
}

function totalSupply() override(ERC721Enumerable) external view returns (uint) {
	return tokenCount;
}

// Tokens are identified by their index one-to-one.
function tokenByIndex(uint index) override(ERC721Enumerable) external view returns (uint) {
	requireToken(index);
	return index;
}

function tokenOfOwnerByIndex(address owner, uint index) external override(ERC721Enumerable) view returns (uint tokenID) {
	requireAddress(owner);
	for (tokenID = 0; tokenID < tokenCount; tokenID++) {
		address a = tokenOwners[tokenID];
		if (a == owner || (a == address(0) && owner == defaultOwner)) {
			if (index == 0) {
				return tokenID;
			}

			--index;
		}
	}
	revert("ERC721 index exceeds balance");
}

function balanceOf(address owner) external override(ERC721) view returns (uint) {
	requireAddress(owner);
	uint balance = 0;
	// count owner matches
	for (uint tokenID = 0; tokenID < tokenCount; tokenID++) {
		address o = tokenOwners[tokenID];
		if (o == owner || (o == address(0) && owner == defaultOwner)) {
			++balance;
		}
	}
	return balance;
}

function ownerOf(uint tokenID) external override(ERC721) view returns (address) {
	requireToken(tokenID);
	return tokenOwners[tokenID];
}

function safeTransferFrom(address from, address to, uint tokenID, bytes calldata data) external override(ERC721) payable {
	this.transferFrom(from, to, tokenID);

	if (msg.sender == tx.origin) { // is contract
		require(ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenID, data) == ERC721TokenReceiver.onERC721Received.selector, "ERC721TokenReceiver mis");
	}
}

function safeTransferFrom(address from, address to, uint tokenID) external override(ERC721) payable {
	return this.safeTransferFrom(from, to, tokenID, "");
}

function transferFrom(address from, address to, uint tokenID) external override(ERC721) payable {
	address owner = this.ownerOf(tokenID); // checks token ID
	require(from == owner, "ERC-721 from \u2415");
	requireAddress(to);

	address approved = tokenApprovals[tokenID];
	require(msg.sender == owner || msg.sender == approved || this.isApprovedForAll(owner, msg.sender), "ERC-721 sender deny");

	// reset approvals from previous owner, if any
	if (approved != address(0)) {
		delete tokenApprovals[tokenID];
		emit Approval(owner, address(0), tokenID);
	}

	// actual transfer
	tokenOwners[tokenID] = to;
	emit Transfer(from, to, tokenID);
}

function approve(address to, uint tokenID) external override(ERC721) payable {
	address owner = this.ownerOf(tokenID); // checks token ID
	require(msg.sender == owner || this.isApprovedForAll(owner, msg.sender), "ERC721 sender deny");
	tokenApprovals[tokenID] = to;
	emit Approval(owner, to, tokenID);
}

// The implementation leaks by design. The operator entries should be cleared with a
// false approved once no longer needed.
function setApprovalForAll(address operator, bool approved) external override(ERC721) {
	requireAddress(operator); // not required by spec
	if (approved) {
		operatorApprovals[msg.sender][operator] = true;
	} else {
		delete operatorApprovals[msg.sender][operator];
	}
	emit ApprovalForAll(msg.sender, operator, approved);
}

function getApproved(uint tokenID) external override(ERC721) view returns (address operator) {
	requireToken(tokenID);
	return tokenApprovals[tokenID];
}

function isApprovedForAll(address owner, address operator) external override(ERC721) view returns (bool) {
	return operatorApprovals[owner][operator];
}

}