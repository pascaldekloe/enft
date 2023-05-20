// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.13;

/// The OPTIONAL methods (of an ERC-20) can be used to improve usability, but
/// interfaces and other contracts MUST NOT expect these values to be present.
/// @title ERC-20 Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-20
interface ERC20Metadata /* is ERC20 */ {
	// Returns the name of the token - e.g. "MyToken".
	function name() external view returns (string memory);

	// Returns the symbol of the token. E.g. “HIX”.
	function symbol() external view returns (string memory);

	// Returns the number of decimals the token uses - e.g. 8, means to divide the
	// token amount by 100000000 to get its user representation.
	function decimals() external view returns (uint8);
}
