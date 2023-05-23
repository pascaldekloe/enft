// https://docs.ethers.io/v5/api/
const { ethers } = require("hardhat");

// https://www.chaijs.com/api/
const { assert, config } = require("chai");
// trims error messages to unreadable assertion failure without
config.truncateThreshold = 1000;


describe("NFTBuyout", function() {

before(async function() {
	// operator deploys contracts
	[this.operator, this.alice, this.bob, this.carol] = await ethers.getSigners();

	this.buyoutFactory      = await ethers.getContractFactory("NFTBuyout");
        this.currencyFactory    = await ethers.getContractFactory("FixedTokenSupply");
        this.nonFungibleFactory = await ethers.getContractFactory("FixedNFTSet");
});

// Alice gets NFT. Bob gets ERC-20.
beforeEach(async function() {
        this.buyout      = await this.buyoutFactory.deploy();
        this.nonFungible = await this.nonFungibleFactory.deploy(3, this.alice.address);
        this.currency    = await this.currencyFactory.deploy(1001, this.bob.address);

	await this.buyout.deployed();
	await this.nonFungible.deployed();
	await this.currency.deployed();

	this.buyoutAsAlice      = this.buyout.connect(this.alice);
	this.buyoutAsBob        = this.buyout.connect(this.bob);
	this.nonFungibleAsAlice = this.nonFungible.connect(this.alice);
	this.nonFungibleAsBob   = this.nonFungible.connect(this.bob);
	this.currencyAsAlice    = this.currency.connect(this.alice);
	this.currencyAsBob      = this.currency.connect(this.bob);
});

context("on initial state", function() {
	it("has no token price", async function() {
		try {
			const tokenID = 1;
			var price = await this.buyout.tokenPrice(this.nonFungible.address, tokenID, this.bob.address);
			assert.fail(`got price ${price}`);
		} catch (e) {
			assert.match(e.message, /no such offer/, "wrong error");
		}
	});

	it("can't redeem", async function() {
		try {
			const tokenID = 1, minPrice = 0;
			await this.buyoutAsAlice.redeemToken(this.nonFungible.address, tokenID, this.bob.address, minPrice, this.currency.address);
			assert.fail("no error");
		} catch (e) {
			assert.match(e.message, /no such offer/, "wrong error");
		}
	});
});

context("on offer", function() {
	// happy flow
	it("redeems tokens", async function() {
		await this.currencyAsBob.approve(this.buyout.address, 10000);

		const decimals = 2, amount = 5, varyType = 0, varyAmount = 0;
		await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals, amount, varyType, varyAmount]);

		const tokenID = 1;
		await this.nonFungibleAsAlice.approve(this.buyout.address, tokenID);

		await this.buyoutAsAlice.redeemToken(this.nonFungible.address, tokenID, this.bob.address, 500, this.currency.address);
		assert.equal(await this.currency.balanceOf(this.alice.address), 500, "balance of Alice");
		assert.equal(await this.nonFungible.ownerOf(tokenID), this.bob.address, "NFT owner");
	});

	it("denies higher price", async function() {
		await this.currencyAsBob.approve(this.buyout.address, 10000);

		const decimals = 2, amount = 5, varyType = 0, varyAmount = 0;
		await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals, amount, varyType, varyAmount]);

		const tokenID = 1;
		await this.nonFungibleAsAlice.approve(this.buyout.address, tokenID);

		try {
			await this.buyoutAsAlice.redeemToken(this.nonFungible.address, tokenID, this.bob.address, 501, this.currency.address);
			assert.fail("no error");
		} catch (e) {
			assert.match(e.message, /trade price miss/, "wrong error");
		}
	});

	it("denies other currency", async function() {
		await this.currencyAsBob.approve(this.buyout.address, 10000);

		const decimals = 2, amount = 5, varyType = 0, varyAmount = 0;
		await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals, amount, varyType, varyAmount]);

		const tokenID = 1;
		await this.nonFungibleAsAlice.approve(this.buyout.address, tokenID);

		var otherCurrency = await this.currencyFactory.deploy(99, this.bob.address);
		try {
			await this.buyoutAsAlice.redeemToken(this.nonFungible.address, tokenID, this.bob.address, 500, otherCurrency.address);
			assert.fail("no error");
		} catch (e) {
			assert.match(e.message, /trade currency miss/, "wrong error");
		}
	});

	it("needs NFT standard", async function() {
		try {
			const decimals = 3, amount = 2, varyType = 0, varyAmount = 0;
			await this.buyoutAsBob.offer(this.currency.address, [this.currency.address, decimals, amount, varyType, varyAmount]);
			assert.fail("no error");
		} catch (e) {
			assert.match(e.message, /need standard NFT/, "wrong error");
		}
	});

	it("needs ERC-20 allowance", async function() {
		try {
			const decimals = 3, amount = 2, varyType = 0, varyAmount = 0;
			await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals, amount, varyType, varyAmount]);
			assert.fail("no error");
		} catch (e) {
			assert.match(e.message, /no payment allowance/, "wrong error");
		}
	});

	it("sets the token price", async function() {
		await this.currencyAsBob.approve(this.buyout.address, 10000);

		const decimals = 3, amount = 2, varyType = 0, varyAmount = 0;
		await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals, amount, varyType, varyAmount]);

		const tokenID = 1;
		var price = await this.buyout.tokenPrice(this.nonFungible.address, tokenID, this.bob.address);
		assert.equal(price.length, 2, "tokenPrice return count");
		assert.equal(price[0], 2000, "price amount");
		assert.equal(price[1], this.currency.address, "price currency");
	});

	it("applies a price ramp-down", async function() {
		await this.currencyAsBob.approve(this.buyout.address, 10000);

		const decimals = 3, amount = 2, varyType = 0, varyAmount = 7;
		await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals, amount, varyType, varyAmount]);

		const tokenID = 5;
		var price = await this.buyout.tokenPrice(this.nonFungible.address, tokenID, this.bob.address);
		assert.equal(price.length, 2, "tokenPrice return count");
		assert.equal(price[0], 1965, "price amount");
		assert.equal(price[1], this.currency.address, "price currency");
	});

	it("updates the token price", async function() {
		await this.currencyAsBob.approve(this.buyout.address, 10000);

		const decimals = 3, amount = 2, varyType = 0, varyAmount = 0;
		await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals, amount, varyType, varyAmount]);
		// update
		await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals + 1, amount + 1, varyType, varyAmount]);

		const tokenID = 1;
		var price = await this.buyout.tokenPrice(this.nonFungible.address, tokenID, this.bob.address);
		assert.equal(price.length, 2, "tokenPrice return count");
		assert.equal(price[0], 30000, "price amount");
		assert.equal(price[1], this.currency.address, "price currency");
	});

	it("retracts on a zero price", async function() {
		await this.currencyAsBob.approve(this.buyout.address, 10000);

		const decimals = 3, amount = 2, varyType = 0, varyAmount = 0;
		await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals, amount, varyType, varyAmount]);
		// update with amount = 0
		await this.buyoutAsBob.offer(this.nonFungible.address, [this.currency.address, decimals + 1, 0, varyType, varyAmount]);

		const tokenID = 1;
		try {
			var price = await this.buyout.tokenPrice(this.nonFungible.address, tokenID, this.bob.address);
			assert.fail(`got price ${price}`);
		} catch (e) {
			assert.match(e.message, /no such offer/, "wrong error");
		}
		try {
			await this.buyoutAsAlice.redeemToken(this.nonFungible.address, tokenID, this.bob.address, 0, this.currency.address);
			assert.fail("no error");
		} catch (e) {
			assert.match(e.message, /no such offer/, "wrong error");
		}
	});

});

});
