// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.13;

/// Creates a standard method to publish and detect what interfaces a smart
/// contract implements.
/// @title ERC-165 Standard Interface Detection
/// @dev See https://eips.ethereum.org/EIPS/eip-165
interface ERC165 {
	/// @notice Query if a contract implements an interface
	/// @param interfaceID The interface identifier, as specified in ERC-165
	/// @dev Interface identification is specified in ERC-165. This function
	///  uses less than 30,000 gas.
	/// @return `true` if the contract implements `interfaceID` and
	///  `interfaceID` is not 0xffffffff, `false` otherwise
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
