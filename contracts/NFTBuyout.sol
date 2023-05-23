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
/// @param target The ERC-721 contract
/// @param buyer The acquisition party
event NFTBuyoutOffer(address indexed target, address buyer);

/// @param RampDown Decrease the amount offered per token identifier, with a
///  fixed quantity, starting with zero, as in: price − (tokenID × varyAmount).
enum TradeVary { RampDown }

// Each NFT-contract:buyer:conditions entry is an individual buyout attempt.
mapping(address => mapping(address => Conditions)) private buyouts;

/// @param currency The ERC-20 unit
/// @param decimals The ERC-20 quantity exponent
/// @param price The token quantity
/// @param varyType The price variant
/// @param varyAmount The varyType quantity
struct Conditions {
	address   currency;
	uint8     decimals;
	uint40    price;
	TradeVary varyType;
	uint40    varyAmount;
}

/// @notice Offer either commits to a new deal, or it updates the previous one.
///  A zero price retracts any ongoing offers (matching target).
/// @dev ⚠️ Be very carefull with a non-fixed tokenSupply. Think about TradeVary.
/// @param target The ERC-721 contract
function offer(address target, Conditions calldata c) public payable {
	if (c.price == 0) {
		delete buyouts[target][msg.sender];
		return;
	}

	// NFT contracts MUST implement ERC-165 by spec
	require(ERC165(target).supportsInterface(type(ERC721).interfaceId), "need standard NFT");

	// fail-fast: trade requires allowance to this contract
	require(ERC20(c.currency).allowance(msg.sender, address(this)) != 0, "no payment allowance");

	buyouts[target][msg.sender] = c;
	emit NFTBuyoutOffer(target, msg.sender);
}

/// @notice Each NFT is subject to a dedicated trade amount.
/// @dev ⚠️ Newly minted tokens may alter expectations.
/// @param target The ERC-721 contract
/// @param tokenID The NFT in subject
/// @return amount The ERC-20 quantity
/// @return currency The ERC-20 contract
function tokenPrice(address target, uint256 tokenID, address buyer) public view returns (uint256 amount, address currency) {
	Conditions memory c = buyouts[target][buyer];
	return (tokenPriceFromConditions(c, tokenID), c.currency);
}

function tokenPriceFromConditions(Conditions memory c, uint256 tokenID) private pure returns (uint256 amount) {
	require(c.price != 0, "no such offer");

	if (c.varyType == TradeVary.RampDown) {
		return (c.price - (tokenID * c.varyAmount)) * (10 ** c.decimals);
	}
	revert("unknow vary type");
}

/// @notice Trade an NFT for ERC-20.
/// @dev Offers can be modified or retracted.
/// @param target The ERC-721 contract
/// @param tokenID The NFT in subject
/// @param buyer The acquisition party
/// @param wantPrice The minimal amount expectation—prevents races
/// @param wantCurrency The ERC-20 unit expectation—prevents races
function redeemToken(address target, uint256 tokenID, address buyer, uint256 wantPrice, address wantCurrency) public {
	require(msg.sender != buyer, "sell to self");

	Conditions memory c = buyouts[target][buyer];
	uint256 price = tokenPriceFromConditions(c, tokenID);
	require(price >= wantPrice, "trade price miss");
	require(c.currency == wantCurrency, "trade currency miss");

	ERC721(target).transferFrom(msg.sender, buyer, tokenID);
	ERC20(wantCurrency).transferFrom(buyer, msg.sender, price);
}

}
