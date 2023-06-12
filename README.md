# ENFT

The `contracts` directory provides interfaces and implementations of EIP token
standards. All payable methods are writen for minimal gas consumption.

Automated tests execute standalone with `npx hardhat test`. Hardhat itself can
be obtained with `npm install --save-dev hardhat`.

This is free and unencumbered software released into the
[public domain](https://creativecommons.org/publicdomain/zero/1.0).

[![Build Status](https://github.com/pascaldekloe/enft/actions/workflows/test.yml/badge.svg)](https://github.com/pascaldekloe/enft/actions/workflows/test.yml)


## Efficiency

A `FixedNFTSet` deployement costs 837 k gas.

Token transfers come in 3 variations.

1. A plain `transferFrom` as the onwer of a token costs 49 k gas.
2. An `approve` costs 48 k gas, with 48 k gas on `tranferFrom`.
3. A `setApprovalForAll` costs 46 k gas, with 49 k gas on `tranferFrom`.


## Use

The `NFTBuyout` contract is ready on the following chains. Please share when you
install on a chain not listed here.

* [Mainnet](https://etherscan.io/address/0xb816782c5bff5dec497d316b070b229c7cd63e83#code)
* [Sepolia](https://sepolia.etherscan.io/address/0x1b9dfecb419029a54b594327ea23d1a0ea0eafff#code)


Custom tokens can simply inherit the `FixedNFTSet` contract.
It is recommended to import contracts with a versioned path only.

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.12;

import "https://github.com/pascaldekloe/enft/blob/v1.1.1/contracts/ERC721Metadata.sol";
import "https://github.com/pascaldekloe/enft/blob/v1.1.1/contracts/FixedNFTSet.sol";


// NFT example with 12 tokens.
contract MyDozen is FixedNFTSet, ERC721Metadata {

// Constructor assigns all 12 tokens to the receiver address.
constructor(address receiver) FixedNFTSet(12, receiver) {
	// initial Transfer emission is optional
	for (uint token = 0; token < 12; token++) {
		emit Transfer(address(0), receiver, token);
	}
}

// SupportsInterface advertises metadata availability.
function supportsInterface(bytes4 interfaceID) public override(FixedNFTSet) pure returns (bool) {
	return super.supportsInterface(interfaceID)
	    || interfaceID == 0x5b5e139f; // ERC721Metadata
}

function name() override(ERC721Metadata) public pure returns (string memory) {
	return "MyDozen";
}

function symbol() override(ERC721Metadata) public pure returns (string memory) {
	return "MDZN";
}

bytes constant tokenURIPrefix = "https://example.com/v1/MyDozen/token";
bytes constant tokenURISuffix = ".json";

function tokenURI(uint256 tokenID) override(ERC721Metadata) public view returns (string memory) {
        requireToken(tokenID);
	bytes1 decimal = bytes1(uint8(48 + tokenID % 10));
	if (tokenID < 10) {
		return string(bytes.concat(tokenURIPrefix, decimal, tokenURISuffix));
	}
	return string(bytes.concat(tokenURIPrefix, bytes1('1'), decimal, tokenURISuffix));
}

}
```

In a Node.js environment you can use the contracts in a project with
`npm install https://github.com/pascaldekloe/enft.git`, and then import with
`import "enft/contracts/ERC721.sol";` instead of the HTTP URL.


## Standard Compliance

*  “Token Standard” EIP-20
*  “Non-Fungible Token Standard” EIP-721
