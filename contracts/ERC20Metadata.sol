// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.4.17;

/// @title ERC-20 Token Standard, optional methods to improve usability
/// @dev See https://eips.ethereum.org/EIPS/eip-20
interface ERC20Metadata /* is ERC20 */ {
	// Returns the name of the token - e.g. "MyToken".
	function name() public view returns (string);

	// Returns the symbol of the token. E.g. “HIX”.
	function symbol() public view returns (string);

	// Returns the number of decimals the token uses - e.g. 8, means to divide the
	// token amount by 100000000 to get its user representation.
	function decimals() public view returns (uint8);
}
