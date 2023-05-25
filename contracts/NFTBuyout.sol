// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.13;

import "./ERC20.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721TokenReceiver.sol";


/// @title NFT Purchase En Masse
/// @notice A buyout trades non-fungible tokens for fungible-token returns. Any
///  number of buyers can make an offer (to the same contract). It is up to the
///  individual NFT owners on whether to make use of any of such offers or not.
/// @dev Only one contract required per chain. Look for NFTBuyoutOffer events to
///  find an existing one.
contract NFTBuyout {

/// @notice Each buyout attempt gets propagated with one offer event. 
/// @param target ERC-721 contract
/// @param buyer acquisition party
event NFTBuyoutOffer(address indexed target, address buyer);

// QualifiedPrice provides an (ERC20) unit to the quanty.
struct QualifiedPrice {
	uint96  amount;   // currency quantity
	address currency; // token contract
}

/// @param None Disable price variation—fixed price for each NFT
/// @param RampDown Decrease the amount offered per token identifier, with a
///  fixed quantity, starting with zero, as in: price − (tokenID × varyAmount).
enum VaryType { None, RampDown }

/// @param scheme algorithm nature, with None for disabled
/// @param data bytes are interpretated according to scheme
struct PriceVary {
	VaryType scheme;
	uint248  data;
}

// private storage unit
struct Record {
	QualifiedPrice price;
	PriceVary      vary;
}

// Each NFT-contract:buyer:record entry is an individual buyout attempt.
mapping(address => mapping(address => Record)) private buyouts;

/// @notice Offer either commits to a new deal, or it updates the previous one.
///  A zero price amount retracts any ongoing offers (matching target).
/// @dev ⚠️ Be very carefull with a non-fixed tokenSupply. Think about PriceVary.
/// @param target ERC-721 contract
function offer(address target, QualifiedPrice calldata price, PriceVary calldata vary) public payable {
	if (price.amount == 0) {
		delete buyouts[target][msg.sender];
		return;
	}

	// NFT contracts MUST implement ERC-165 by spec
	require(ERC165(target).supportsInterface(type(ERC721).interfaceId), "need standard NFT");

	// fail-fast: trade requires allowance to this contract
	require(ERC20(price.currency).allowance(msg.sender, address(this)) != 0, "no payment allowance");

	buyouts[target][msg.sender] = Record({price: price, vary: vary});

	emit NFTBuyoutOffer(target, msg.sender);
}

/// @notice Each NFT is subject to a dedicated trade amount.
/// @dev ⚠️ Newly minted tokens may alter expectations.
/// @param target ERC-721 contract
/// @param tokenID NFT in subject
/// @param buyer acquisition party
/// @return amount ERC-20 quantity
/// @return currency ERC-20 contract
function tokenPrice(address target, uint256 tokenID, address buyer) public view returns (uint256 amount, address currency) {
	Record memory record = buyouts[target][buyer];
	amount = uint256(record.price.amount);
	require(amount != 0, "no such offer");
	currency = record.price.currency;

	// apply price variation, if any
	VaryType scheme = record.vary.scheme;
	if (scheme == VaryType.RampDown) {
		amount -= uint256(record.vary.data) * tokenID;
	} else if (scheme != VaryType.None) {
		revert("unknow vary type");
	}

	return (amount, currency);
}

/// @notice Trade an NFT for ERC-20.
/// @dev Offers can be modified or retracted.
/// @param target ERC-721 contract
/// @param tokenID NFT in subject
/// @param buyer acquisition party
/// @param wantPrice minimal amount expectation—prevents races
/// @param wantCurrency ERC-20 unit expectation—prevents races
function redeemToken(address target, uint256 tokenID, address buyer, uint256 wantPrice, address wantCurrency) public {
	require(msg.sender != buyer, "sell to self");

	(uint256 amount, address currency) = tokenPrice(target, tokenID, buyer);
	require(amount >= wantPrice, "trade price miss");
	require(currency == wantCurrency, "trade currency miss");

	ERC721(target).transferFrom(msg.sender, buyer, tokenID);
	ERC20(currency).transferFrom(buyer, msg.sender, amount);
}

}
