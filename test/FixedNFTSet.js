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

context("gas consumption", function() {
	it("should limit instantiation costs", async function() {
		var tx = await this.c.deployTransaction.wait();
		assert.isBelow(tx.gasUsed, 1500000, "gas used on deployment");

		var estimate = this.c.estimateGas;
		assert.isAtMost(await estimate.ownerOf(1), 24250, "gas used on #ownerOf");
	});

	it("should limit approval costs", async function() {
		var asAlice = this.asAlice.estimateGas;
		assert.isAtMost(await asAlice.approve(this.bob.address, 1), 48812, "gas used on #approve");
		assert.isAtMost(await asAlice.setApprovalForAll(this.carol.address, 1), 46658, "gas used on #setApprovalForAll");
		assert.isAtMost(await asAlice.setApprovalForAll(this.carol.address, 0), 27023, "gas used on #setApprovalForAll NOP");
	});

	it("should limit transfer costs", async function() {
		// transfer coin #0 from Alice to Bob as owner
		var asAlice = this.asAlice.estimateGas;
		assert.isAtMost(await asAlice.transferFrom(this.alice.address, this.bob.address, 0), 49812, "gas used as owner");

		// transfer coin #1 from Alice to Bob with approval
		await this.asAlice.approve(this.bob.address, 1);
		var asBob   = this.asAlice.estimateGas;
		assert.isAtMost(await asBob.transferFrom(this.alice.address, this.bob.address, 1), 55151, "gas used with approve");

		// transfer coin #2 from Alice to Bob with operator
		await this.asAlice.setApprovalForAll(this.carol.address, true);
		var asCarol = this.asAlice.estimateGas;
		assert.isAtMost(await asCarol.transferFrom(this.alice.address, this.bob.address, 2), 49824, "gas used as operator");
	});
});

});