// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

import "./ERC165.sol";
import "./ERC20.sol";


// FixedTokenSupply manages a fixed amount of fungible tokens.
contract FixedTokenSupply is ERC20, ERC165 {

uint public override(ERC20) immutable totalSupply;

// Balances tracks all token owners.
mapping(address => uint) private balances;

// The token-owner:token-receiver:approved-quantity entries are always non-zero.
mapping(address => mapping(address => uint)) approvals;

// Constructor mints n tokens, and transfers each token to the receiver address.
constructor(uint n, address receiver) {
	totalSupply = n;
	balances[receiver] = n;
	emit Transfer(address(0), receiver, n);
}

function supportsInterface(bytes4 interfaceID) public virtual override(ERC165) pure returns (bool) {
	// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
	return interfaceID == 0x36372b07  // ERC20
	    || interfaceID == 0x01ffc9a7; // ERC165
}

function balanceOf(address owner) public override(ERC20) view returns (uint) {
	return balances[owner];
}

function transfer(address to, uint amount) public override(ERC20) returns (bool) {
	// msg.sender is authorized to operate on his own tokens
	authorizedTransferFrom(msg.sender, to, amount);
	return true; // always
}

function transferFrom(address from, address to, uint amount) public override(ERC20) returns (bool) {
	// check approval
	uint approved = allowance(from, msg.sender);
	require(approved >= amount, "insufficient allowance");
	// operate with permission
	authorizedTransferFrom(from, to, amount);
	// update aproval
	authorizedApprove(from, msg.sender, approved - amount);
	return true; // always
}

// AuthorizedTransferFrom assumes that msg.sender is permitted to withdraw the
// amount from the from address.
function authorizedTransferFrom(address from, address to, uint amount) private {
	// validate sender balance
	uint saldo = balances[from];
	require(saldo >= amount, "insufficient balance");
	// deduct from sender balance
	balances[from] = saldo - amount;
	// accumulute on receiver balance
	balances[to] += amount;
	// log opertation
	emit Transfer(from, to, amount);
}

function approve(address spender, uint amount) public override(ERC20) returns (bool) {
	// msg.sender is authorized to operate on his own tokens
	authorizedApprove(msg.sender, spender, amount);
	return true; // always
}

// AuthorizedApprove assumes msg.sender is permitted to set the allowance amount
// of spender for the owner address.
function authorizedApprove(address owner, address spender, uint amount) private {
	if (amount == 0) {
		delete approvals[owner][spender];
	} else {
		approvals[owner][spender] = amount;
	}
	emit Approval(owner, spender, amount);
}

function allowance(address owner, address spender) public override(ERC20) view returns (uint) {
	return approvals[owner][spender];
}

}
