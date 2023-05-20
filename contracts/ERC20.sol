// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

/// A standard interface for tokens, without the OPTIONAL methods.
/// @title ERC-20 Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-20
interface ERC20 {
	// MUST trigger when tokens are transferred, including zero value transfers.
	//
	// A token contract which creates new tokens SHOULD trigger a Transfer event
	// with the from address set to 0x0 when tokens are created.
	event Transfer(address indexed from, address indexed to, uint256 value);

	// MUST trigger on any successful call to approve(address spender, uint256 value).
	event Approval(address indexed owner, address indexed spender, uint256 value);

	// Returns the total token supply.
	function totalSupply() external view returns (uint256);

	// Returns the account balance of another account with address owner.
	function balanceOf(address owner) external view returns (uint256);

	// Transfers value amount of tokens to address to, and MUST fire the Transfer
	// event. The function SHOULD throw if the message caller’s account balance does
	// not have enough tokens to spend.
	//
	// Note Transfers of 0 values MUST be treated as normal transfers and fire the
	// Transfer event.
	function transfer(address to, uint256 value) external returns (bool success);

	// Transfers value amount of tokens from address from to address to, and MUST
	// fire the Transfer event.
	//
	// The transferFrom method is used for a withdraw workflow, allowing contracts
	// to transfer tokens on your behalf. This can be used for example to allow a
	// contract to transfer tokens on your behalf and/or to charge fees in
	// sub-currencies. The function SHOULD throw unless the from account has
	// deliberately authorized the sender of the message via some mechanism.
	//
	// Note Transfers of 0 values MUST be treated as normal transfers and fire the
	// Transfer event.
	function transferFrom(address from, address to, uint256 value) external returns (bool success);

	// Allows spender to withdraw from your account multiple times, up to the
	// value amount. If this function is called again it overwrites the current
	// allowance with value.
	//
	// NOTE: To prevent attack vectors like the one described here
	// <https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/>
	// and discussed here <https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729>,
	// clients SHOULD make sure to create user interfaces in such a way that they
	// set the allowance first to 0 before setting it to another value for the same
	// spender. THOUGH The contract itself shouldn’t enforce it, to allow backwards
	// compatibility with contracts deployed before.
	function approve(address spender, uint256 value) external returns (bool success);

	// Returns the amount which spender is still allowed to withdraw from owner.
	function allowance(address owner, address spender) external view returns (uint256 remaining);
}
