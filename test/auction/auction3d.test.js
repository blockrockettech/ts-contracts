const {BN, constants, expectEvent, expectRevert, ether, balance} = require('openzeppelin-test-helpers');

const gasSpent = require('../gas-spent-helper');

const {expect} = require('chai');

const TwistedSisterAccessControls = artifacts.require('TwistedSisterAccessControls');
const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const TwistedSister3DToken = artifacts.require('TwistedSister3DToken');
const TwistedSisterArtistCommissionRegistry = artifacts.require('TwistedSisterArtistCommissionRegistry');
const TwistedSisterArtistFundSplitter = artifacts.require('TwistedSisterArtistFundSplitter');
const TwistedSister3DAuction = artifacts.require('TwistedSister3DAuction');

contract.only('Twisted 3D Auction Tests', function ([
                                                        creator,
                                                        buyer,
                                                        random,
                                                        twistHolder1,
                                                        ...accounts
                                                    ]) {
    const fromCreator = {from: creator};
    const fromRandom = {from: random};

    // Commission splits and artists
    const commission = {
        percentages: [
            new BN(5000),
            new BN(5000),
        ],
        artists: [
            accounts[0],
            accounts[1],
        ]
    };

    const baseURI = "ipfs/";
    const randIPFSHash = "QmRLHatjFTvm3i4ZtZU8KTGsBTsj3bLHLcL8FbdkNobUzm";

    const minBid = ether('0.02');
    const halfEth = ether('0.5');
    const oneEth = ether('1');
    const justOverOneEth = ether('1.01');
    const oneHalfEth = ether('1.5');

    async function sendValue(from, to, value) {
        await web3.eth.sendTransaction({from, to, value});
    }

    beforeEach(async function () {
        this.accessControls = await TwistedSisterAccessControls.new(fromCreator);
        expect(await this.accessControls.isWhitelisted(creator)).to.be.true;

        this.artistCommissionRegistry = await TwistedSisterArtistCommissionRegistry.new(this.accessControls.address, fromCreator);
        await this.artistCommissionRegistry.setCommissionSplits(commission.percentages, commission.artists, fromCreator);
        const {
            _percentages,
            _artists
        } = await this.artistCommissionRegistry.getCommissionSplits();
        expect(JSON.stringify(_percentages)).to.be.deep.equal(JSON.stringify(commission.percentages));
        expect(_artists).to.be.deep.equal(commission.artists);

        this.artistFundSplitter = await TwistedSisterArtistFundSplitter.new(this.artistCommissionRegistry.address, fromCreator);

        this.twistToken = await TwistedSisterToken.new(baseURI, this.accessControls.address, 0, this.artistFundSplitter.address, fromCreator);
        this.twist3DToken = await TwistedSister3DToken.new(baseURI, this.accessControls.address, this.artistFundSplitter.address, this.twistToken.address, fromCreator);

        this.auction = await TwistedSister3DAuction.new(
            this.accessControls.address,
            this.twist3DToken.address,
            this.artistFundSplitter.address,
            this.twistToken.address
        );

        await this.accessControls.addWhitelisted(this.auction.address);
        expect(await this.accessControls.isWhitelisted(this.auction.address)).to.be.true;

        await this.twistToken.createTwisted(1, 0, randIPFSHash, twistHolder1);
    });

    describe('happy path', function () {
        it('can purchase the TWIST3D token and split funds', async function () {
            const balancesBefore = {
                twistHolder1: await balance.tracker(twistHolder1),
                artist1: await balance.tracker(commission.artists[0]),
                artist2: await balance.tracker(commission.artists[1]),
            };

            await sendValue(buyer, this.auction.address, oneEth);
            ({logs: this.logs} = await this.auction.issue3DTwistToken(randIPFSHash, fromCreator));
            expectEvent.inLogs(this.logs, 'TWIST3DIssued', {
                _buyer: buyer,
                _value: oneEth
            });

            expect(await this.twist3DToken.ownerOf(1)).to.be.equal(buyer);
            await verifyFundSplitting(balancesBefore, oneEth, this.twistToken);
        });
    });

    describe('issuing 3D token', function () {
        describe('when multiple payments have arrived', function () {
            it('sends the token to the highest payment address', async function () {
                const balancesBefore = {
                    twistHolder1: await balance.tracker(twistHolder1),
                    artist1: await balance.tracker(commission.artists[0]),
                    artist2: await balance.tracker(commission.artists[1]),
                };

                await sendValue(buyer, this.auction.address, oneEth);
                await sendValue(random, this.auction.address, halfEth);
                ({logs: this.logs} = await this.auction.issue3DTwistToken(randIPFSHash, fromCreator));
                expect(await this.twist3DToken.ownerOf(1)).to.be.equal(buyer);

                await verifyFundSplitting(balancesBefore, oneHalfEth, this.twistToken);
            });
        });

        describe('reverts', function () {
            it('when trying to issue a token more than once', async function() {
                await sendValue(buyer, this.auction.address, oneEth);
                ({logs: this.logs} = await this.auction.issue3DTwistToken(randIPFSHash, fromCreator));
                await expectRevert(
                    this.auction.issue3DTwistToken(randIPFSHash, fromCreator),
                    "ERC721: token already minted."
                );
            });

            it('when trying to issue a token to the zero address', async function () {
                await expectRevert.unspecified(this.auction.issue3DTwistToken(randIPFSHash, fromCreator));
            });
        });
    });

    describe('withdrawing funds', function () {
        describe('when whitelisted', function () {
            describe('when contract has a balance', function () {
                beforeEach(async function () {
                    await sendValue(creator, this.auction.address, oneEth);
                });

                async function withdrawAllFunds(context) {
                    const creatorBalance = await balance.tracker(creator);
                    ({receipt: context.receipt} = await context.auction.withdrawAllFunds(fromCreator));
                    (await creatorBalance.delta()).should.be.bignumber.equal(oneEth.sub(gasSpent(context.receipt)));
                }

                it('sends the contract balance to the sender', async function () {
                    await withdrawAllFunds(this);
                });
            });
        });

        describe('when not whitelisted', function () {
            describe('when contract has a balance', function () {
                it('reverts', async function () {
                    await sendValue(creator, this.auction.address, oneEth);
                    await expectRevert(
                        this.auction.withdrawAllFunds(fromRandom),
                        'Caller not whitelisted'
                    );
                });
            });
        });
    });

    describe('admin functions', function () {
        it('can update buyer', async function () {
            expect(await this.auction.buyer()).to.be.equal(constants.ZERO_ADDRESS);
            await this.auction.updateBuyer(random, fromCreator);
            expect(await this.auction.buyer()).to.be.equal(random);
        });

        it('can update artist fundsplitter', async function () {
            expect(await this.auction.artistFundSplitter()).to.be.equal(this.artistFundSplitter.address);
            await this.auction.updateArtistFundSplitter(random, fromCreator);
            expect(await this.auction.artistFundSplitter()).to.be.equal(random);
        });

        it('reverts when not whitelisted', async function () {
            await expectRevert(
                this.auction.updateBuyer(random, fromRandom),
                "Caller not whitelisted"
            );

            await expectRevert(
                this.auction.updateArtistFundSplitter(random, fromRandom),
                "Caller not whitelisted"
            );

            await expectRevert(
                this.auction.withdrawAllFunds(fromRandom),
                "Caller not whitelisted"
            );

            await expectRevert(
                this.auction.issue3DTwistToken(random, fromRandom),
                "Caller not whitelisted"
            );
        });
    });

    const verifyFundSplitting = async (balancesBefore, totalSplit, twistToken) => {
        const singleUnitOfValue = totalSplit.div(new BN('100'));

        const tokenHolderSplit = singleUnitOfValue.mul(new BN('90'));
        const individualHolderSplit = tokenHolderSplit.div(await twistToken.totalSupply());
        expect(await balancesBefore.twistHolder1.delta()).to.be.bignumber.equal(individualHolderSplit);

        const artistSplit = singleUnitOfValue.mul(new BN('10'));
        const individualArtistSplit = artistSplit.div(new BN(commission.artists.length.toString()));
        expect(await balancesBefore.artist1.delta()).to.be.bignumber.equal(individualArtistSplit);
        expect(await balancesBefore.artist2.delta()).to.be.bignumber.equal(individualArtistSplit);
    };
});