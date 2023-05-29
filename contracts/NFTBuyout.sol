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

/// @param None Disable price variation—fixed price for each NFT.
/// @param RampDownMult Decrease the amount offered per token identifier, with a
///  fixed quantity, starting with zero, as in: price − (tokenID × varyAmount).
enum PriceVary { None, RampDownMult }

/// @notice The buyout price is per NFT, with an optional variantion applied.
/// @param amount currency quantity
/// @param currency ERC-20 contract
/// @param vary difference between NFT, with None for disabled
/// @param data bytes are interpretated according to vary
struct Price {
	uint96    amount;
	address   currency;
	PriceVary vary;
	uint248   data;
}

// Each NFT-contract:buyer:price entry is an individual buyout attempt.
mapping(address => mapping(address => Price)) private buyouts;

/// @notice Offer either commits to a new deal, or it updates the previous one.
///  A zero price amount retracts any ongoing offers (matching target).
/// @dev ⚠️ Be very carefull with a non-fixed tokenSupply. Think about PriceVary.
/// @param target ERC-721 contract
function offer(address target, Price calldata price) public payable {
	if (price.amount == 0) {
		delete buyouts[target][msg.sender];
		return;
	}

	// NFT contracts MUST implement ERC-165 by spec
	require(ERC165(target).supportsInterface(type(ERC721).interfaceId), "need standard NFT");

	if (price.vary == PriceVary.RampDownMult) {
		require(ERC165(target).supportsInterface(type(ERC721Enumerable).interfaceId), "ramp-down needs enumerable NFT");

		// determine negative-price threshold
		uint rampDown = uint(price.data);
		require(rampDown != 0, "zero ramp-down");
		uint maxID = uint(price.amount) / rampDown;

		// check every token currently present
		uint n = ERC721Enumerable(target).totalSupply();
		for (uint i = 0; i < n; i++) {
			require(ERC721Enumerable(target).tokenByIndex(i) <= maxID, "token ID underflows ramp-down");
		}
	}

	// fail-fast: trade requires allowance to this contract
	require(ERC20(price.currency).allowance(msg.sender, address(this)) != 0, "no payment allowance");

	buyouts[target][msg.sender] = price;

	emit NFTBuyoutOffer(target, msg.sender);
}

/// @notice Each NFT is subject to a dedicated trade amount.
/// @dev ⚠️ Newly minted tokens may alter expectations. There is no check on the
///  tokenID as non-existing tokens simply won't transfer per ERC-721 standard.
/// @param target ERC-721 contract
/// @param tokenID NFT in subject
/// @param buyer acquisition party
/// @return amount ERC-20 quantity
/// @return currency ERC-20 contract
function tokenPrice(address target, uint256 tokenID, address buyer) public view returns (uint256 amount, address currency) {
	Price memory price = buyouts[target][buyer];
	amount = uint256(price.amount);
	require(amount != 0, "no such offer");
	currency = price.currency;

	// apply price variation, if any
	PriceVary vary = price.vary;
	if (vary == PriceVary.RampDownMult) {
		amount -= uint256(price.data) * tokenID;
	} else if (vary != PriceVary.None) {
		revert("unknow vary type");
	}

	return (amount, currency);
}

/// @notice Trade an NFT for ERC-20.
/// @dev Tokens can be redeemed more than once. Offers can be modified or retracted.
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
