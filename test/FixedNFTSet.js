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

});
