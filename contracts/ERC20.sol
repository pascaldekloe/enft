// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.4.17;

/// @title ERC-20 Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-20
interface ERC20 {
	// MUST trigger when tokens are transferred, including zero value transfers.
	//
	// A token contract which creates new tokens SHOULD trigger a Transfer event
	// with the _from address set to 0x0 when tokens are created.
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	// MUST trigger on any successful call to approve(address _spender, uint256 _value).
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	// Returns the total token supply.
	function totalSupply() public view returns (uint256);

	// Returns the account balance of another account with address _owner.
	function balanceOf(address _owner) public view returns (uint256 balance);

	// Transfers _value amount of tokens to address _to, and MUST fire the Transfer
	// event. The function SHOULD throw if the message caller’s account balance does
	// not have enough tokens to spend.
	//
	// Note Transfers of 0 values MUST be treated as normal transfers and fire the
	// Transfer event.
	function transfer(address _to, uint256 _value) public returns (bool success);

	// Transfers _value amount of tokens from address _from to address _to, and MUST
	// fire the Transfer event.
	//
	// The transferFrom method is used for a withdraw workflow, allowing contracts
	// to transfer tokens on your behalf. This can be used for example to allow a
	// contract to transfer tokens on your behalf and/or to charge fees in
	// sub-currencies. The function SHOULD throw unless the _from account has
	// deliberately authorized the sender of the message via some mechanism.
	//
	// Note Transfers of 0 values MUST be treated as normal transfers and fire the
	// Transfer event.
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

	// Allows _spender to withdraw from your account multiple times, up to the
	// _value amount. If this function is called again it overwrites the current
	// allowance with _value.
	//
	// NOTE: To prevent attack vectors like the one described here
	// <https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/>
	// and discussed here <https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729>,
	// clients SHOULD make sure to create user interfaces in such a way that they
	// set the allowance first to 0 before setting it to another value for the same
	// spender. THOUGH The contract itself shouldn’t enforce it, to allow backwards
	// compatibility with contracts deployed before.
	function approve(address _spender, uint256 _value) public returns (bool success);

	// Returns the amount which _spender is still allowed to withdraw from _owner.
	function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}
