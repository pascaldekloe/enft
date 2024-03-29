// https://docs.ethers.io/v5/api/
const { ethers } = require("hardhat");

// https://www.chaijs.com/api/
const { assert } = require("chai");


describe("FixedNFTSet", function() {

before(async function() {
	[this.operator, this.alice, this.bob, this.carol] = await ethers.getSigners();
	this.factory = await ethers.getContractFactory("FixedNFTSet");
});

beforeEach(async function() {
	this.c = await this.factory.deploy(3, this.alice.address);
	await this.c.deployed();

	this.asAlice = this.c.connect(this.alice);
	this.asBob   = this.c.connect(this.bob);
	this.asCarol = this.c.connect(this.carol);
});

context("on initial state", function() {
	it("should have 3 tokens: 0, 1, and 2", async function() {
		assert.equal(await this.c.totalSupply(), 3, "#totalSupply count");

		assert.equal(await this.c.tokenByIndex(0), 0, "token ID by index 0");
		assert.equal(await this.c.tokenByIndex(1), 1, "token ID by index 0");
		assert.equal(await this.c.tokenByIndex(2), 2, "token ID by index 0");
	});

	it("should assign all tokens to alice", async function() {
		assert.equal(await this.c.ownerOf(0), this.alice.address, "owner of token #0");
		assert.equal(await this.c.ownerOf(1), this.alice.address, "owner of token #1");
		assert.equal(await this.c.ownerOf(2), this.alice.address, "owner of token #2");

		assert.equal(await this.c.balanceOf(this.operator.address), 0, "balance of operator");
		assert.equal(await this.c.balanceOf(this.alice.address), 3, "balance of alice");
		assert.equal(await this.c.balanceOf(this.bob.address), 0, "balance of bob");

		assert.equal(await this.c.tokenOfOwnerByIndex(this.alice.address, 0), 0, "token[0] of alice");
		assert.equal(await this.c.tokenOfOwnerByIndex(this.alice.address, 1), 1, "token[1] of alice");
		assert.equal(await this.c.tokenOfOwnerByIndex(this.alice.address, 2), 2, "token[2] of alice");
	});

	it("should approve none", async function() {
		assert.equal(await this.c.getApproved(0), 0, "approved of token #0");
		assert.equal(await this.c.getApproved(1), 0, "approved of token #1");
		assert.equal(await this.c.getApproved(2), 0, "approved of token #2");
	});
});

context("on EIP-165 check", function() {
	it("supportsInterface", async function() {
		// required by EIP-165
		assert.isFalse(await this.c.supportsInterface("0xffffffff"), "deny 0xffffffff");
		// match self
		assert.isTrue(await this.c.supportsInterface("0x01ffc9a7"), "ERC165");
		// double-check literal value
		assert.isTrue(await this.c.supportsInterface(this.c.interface.getSighash('supportsInterface')), "ERC165 getSighash");
		// check each byte
		assert.isFalse(await this.c.supportsInterface("0x02ffc9a7"), "ERC165 byte 1 mis");
		assert.isFalse(await this.c.supportsInterface("0x01efc9a7"), "ERC165 byte 2 mis");
		assert.isFalse(await this.c.supportsInterface("0x01ffcaa7"), "ERC165 byte 3 mis");
		assert.isFalse(await this.c.supportsInterface("0x01ffc9a8"), "ERC165 byte 4 mis");

		// NFT interfaces
		assert.isTrue(await this.c.supportsInterface("0x80ac58cd"), "ERC721");
		assert.isFalse(await this.c.supportsInterface("0x150b7a02"), "ERC721TokenReceiver");
		assert.isFalse(await this.c.supportsInterface("0x5b5e139f"), "ERC721Metadata");
		assert.isTrue(await this.c.supportsInterface("0x780e9d63"), "ERC721Enumerable");
	});
});

context("gas consumption", function() {
	it("has a fixed limit or ERC-165", async function() {
		// “This function uses less than 30,000 gas.”
		// — ERC-165: Standard Interface Detection
		var estimate = this.c.estimateGas;
		assert.isAtMost(await estimate.supportsInterface(0x01ffc9a7), 30000, "gas used for own interface check");
		assert.isAtMost(await estimate.supportsInterface(0xffffffff), 30000, "gas used for opt-out interface check");
	});

	it("should limit instantiation costs", async function() {
		var tx = await this.c.deployTransaction.wait();
		assert.isAtMost(tx.gasUsed, 836941, "gas used on deployment");

		var estimate = this.c.estimateGas;
		assert.isAtMost(await estimate.ownerOf(1), 23852, "gas used on #ownerOf");
	});

	it("should limit approval costs", async function() {
		var asAlice = this.asAlice.estimateGas;
		assert.isAtMost(await asAlice.approve(this.bob.address, 1), 48435, "gas used on #approve");
		assert.isAtMost(await asAlice.setApprovalForAll(this.carol.address, 1), 46137, "gas used on #setApprovalForAll");
		assert.isAtMost(await asAlice.setApprovalForAll(this.carol.address, 0), 26618, "gas used on #setApprovalForAll NOP");
	});

	it("should limit transfer costs", async function() {
		// transfer coin #0 from Alice to Bob as owner
		var estimateAsAlice = this.asAlice.estimateGas;
		assert.isAtMost(await estimateAsAlice.transferFrom(this.alice.address, this.bob.address, 0), 49235, "gas used as owner");

		// transfer coin #1 from Alice to Bob with approval
		assert.isAtMost(await estimateAsAlice.approve(this.bob.address, 1), 48435, "gas used on approve");
		await this.asAlice.approve(this.bob.address, 1);
		var estimateAsBob = this.asAlice.estimateGas;
		assert.isAtMost(await estimateAsBob.transferFrom(this.alice.address, this.bob.address, 1), 54479, "gas used with approve");

		// transfer coin #2 from Alice to Bob with operator
		assert.isAtMost(await estimateAsAlice.setApprovalForAll(this.carol.address, true), 46137, "gas used on approve for all");
		await this.asAlice.setApprovalForAll(this.carol.address, true);
		var estimateAsCarol = this.asAlice.estimateGas;
		assert.isAtMost(await estimateAsCarol.transferFrom(this.alice.address, this.bob.address, 2), 49247, "gas used as operator");
	});
});

});
