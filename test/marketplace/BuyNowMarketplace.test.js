const TwistedSisterAccessControls = artifacts.require('TwistedSisterAccessControls');
const TwistedSisterArtistCommissionRegistry = artifacts.require('TwistedSisterArtistCommissionRegistry');
const TwistedSisterArtistFundSplitter = artifacts.require('TwistedSisterArtistFundSplitter');
const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const BuyNowNFTMarketplace = artifacts.require('BuyNowNFTMarketplace');

const {BN, expectEvent, expectRevert, balance} = require('openzeppelin-test-helpers');

contract.only('BuyNowNFTMarketplace', ([_, creator, minter, tokenOwner, anyone, wallet, newOwner, another, ...accounts]) => {

    const firstTokenId = new BN(1);
    const secondTokenId = new BN(2);
    const thirdTokenId = new BN(3);
    const forthTokenId = new BN(4);
    const unknownTokenId = new BN(999);
    const listPrice = new BN(1000000);

    // Commission splits and artists
    const commission = {
        percentages: [
            new BN(6000),
            new BN(4000),
        ],
        artists: [
            newOwner,
            another,
        ]
    };

    const baseURI = 'ipfs/';

    beforeEach(async function () {
        // Create 721 contract
        this.accessControls = await TwistedSisterAccessControls.new({from: creator});
        await this.accessControls.addWhitelisted(minter, {from: creator});
        (await this.accessControls.isWhitelisted(creator)).should.be.true;
        (await this.accessControls.isWhitelisted(minter)).should.be.true;

        this.artistCommissionRegistry = await TwistedSisterArtistCommissionRegistry.new(this.accessControls.address, { from: creator });
        await this.artistCommissionRegistry.setCommissionSplits(commission.percentages, commission.artists, { from: creator });
        const {
            _percentages,
            _artists
        } = await this.artistCommissionRegistry.getCommissionSplits();
        expect(JSON.stringify(_percentages)).to.be.deep.equal(JSON.stringify(commission.percentages));
        expect(_artists).to.be.deep.equal(commission.artists);

        this.auctionFundSplitter = await TwistedSisterArtistFundSplitter.new(this.artistCommissionRegistry.address, { from: creator });

        this.nft = await TwistedSisterToken.new(baseURI, this.accessControls.address, 0, this.auctionFundSplitter.address, {from: creator});

        // Mint 721s
        await this.nft.createTwisted(0, 0, "", tokenOwner, {from: creator});
        await this.nft.createTwisted(0, 0, "", tokenOwner, {from: creator});
        await this.nft.createTwisted(0, 0, "", tokenOwner, {from: creator});
        await this.nft.createTwisted(0, 0, "", tokenOwner, {from: creator});

        this.marketplace = await BuyNowNFTMarketplace.new(this.nft.address, {from: creator});

        // approve markeplace to sell card on behalf of token owner
        await this.nft.approve(this.marketplace.address, firstTokenId, {from: tokenOwner});

        const {logs} = await this.marketplace.listToken(firstTokenId, listPrice, {from: tokenOwner});
        expectEvent.inLogs(
            logs,
            `Listing`,
            {_seller: tokenOwner, _tokenId: firstTokenId, _priceInWei: listPrice}
        );
    });

    context('ensure public access correct', function () {

        it('returns nft', async function () {
            (await this.marketplace.nft()).should.be.equal(this.nft.address);
        });
    });

    context('list token', function () {

        it('returns listed token', async function () {
            const listed = await this.marketplace.listedTokens();

            listed.length.should.be.equal(1);
            listed[0].should.be.bignumber.equal(firstTokenId);
            (await this.marketplace.listedTokenPrice(firstTokenId)).should.be.bignumber.equal(listPrice);
        });

        it('should revert already listed', async function () {
            await expectRevert(
                this.marketplace.listToken(firstTokenId, listPrice, {from: tokenOwner}),
                "Must not be already listed"
            );
        });

        it('should revert if no price', async function () {
            await this.nft.approve(this.marketplace.address, secondTokenId, {from: tokenOwner});
            await expectRevert(
                this.marketplace.listToken(secondTokenId, 0, {from: tokenOwner}),
                "Must have a positive price"
            );
        });

        it('should revert if not owner', async function () {
            await expectRevert(
                this.marketplace.listToken(thirdTokenId, 0, {from: anyone}),
                "You are not the owner of the NFT"
            );
        });
    });

    context('delist token', function () {
        it('sets price to zero when delisting', async function () {
            const {logs} = await this.marketplace.delistToken(firstTokenId, {from: tokenOwner});
            expectEvent.inLogs(
                logs,
                `Delisting`,
                {_seller: tokenOwner, _tokenId: firstTokenId}
            );

            (await this.marketplace.listedTokenPrice(firstTokenId)).should.be.bignumber.equal('0');
        });

        it('should revert if not owner', async function () {
            await expectRevert(
                this.marketplace.delistToken(firstTokenId, {from: anyone}),
                "You are not the owner of the NFT"
            );
        });
    });

    context('buy now', function () {
        it('successfully buys token', async function () {
            (await this.nft.ownerOf(firstTokenId)).should.be.equal(tokenOwner);

            // give approval
            await this.nft.approve(this.marketplace.address, firstTokenId, {from: tokenOwner});

            const preWalletBalance = await balance.current(wallet);
            const preTokenOwnerBalance = await balance.current(tokenOwner);

            const {logs} = await this.marketplace.buyNow(firstTokenId, {from: anyone, value: listPrice});
            expectEvent.inLogs(
                logs,
                `Purchase`,
                {_buyer: anyone, _tokenId: firstTokenId, _priceInWei: listPrice}
            );

            // transferred to new home!
            (await this.nft.ownerOf(firstTokenId)).should.be.equal(anyone);

            const postWalletBalance = await balance.current(wallet);
            const postTokenOwnerBalance = await balance.current(tokenOwner);


        });

        it('should revert if not listed', async function () {
            await expectRevert(
                this.marketplace.buyNow(forthTokenId, {from: anyone, value: listPrice}),
                "Token not listed"
            );
        });

        it('should revert if no price', async function () {
            // give approval
            await this.nft.approve(this.marketplace.address, firstTokenId, {from: tokenOwner});

            await expectRevert(
                this.marketplace.buyNow(firstTokenId, {from: anyone, value: 0}),
                "Value is below asking price"
            );
        });
    });
});
