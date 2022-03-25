# ENFT

The `contracts` directory provides interfaces and implementations of EIP token
standards. All payable methods are writen for minimal gas consumption.

Automated tests execute standalone with `npx hardhat test`.


## Use

It is recommended to import contracts with a versioned path only.

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.12;

import "https://github.com/pascaldekloe/enft/blob/v1.0.0/contracts/ERC165.sol";
import "https://github.com/pascaldekloe/enft/blob/v1.0.0/contracts/ERC721Metadata.sol";
import "https://github.com/pascaldekloe/enft/blob/v1.0.0/contracts/FixedNFTSet.sol";


// NFT example with 12 tokens.
contract ADozen is FixedNFTSet, ERC721Metadata {

// Constructor assigns all 12 tokens to owner.
constructor(address owner) FixedNFTSet(12, owner) {
}

// SupportsInterface advertises metadata availability.
function supportsInterface(bytes4 interfaceID) public override(FixedNFTSet) pure returns (bool) {
	return super.supportsInterface(interfaceID)
	    || interfaceID == 0x5b5e139f; // ERC721Metadata
}

function name() override(ERC721Metadata) public pure returns (string memory) {
	return "Dozenth";
}

function symbol() override(ERC721Metadata) public pure returns (string memory) {
	return "DZNTH";
}

bytes constant tokenURIPrefix = "https://example.com/v1/adozen/token";
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
`import "enft/contracts/ERC721.sol";` instead of their HTTP URL.


## Standard Compliance

*  “Token Standard” EIP-20
*  “Non-Fungible Token Standard” EIP-721
