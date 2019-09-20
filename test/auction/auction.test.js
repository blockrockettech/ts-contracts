const { BN, constants, expectEvent, expectRevert, ether, balance } = require('openzeppelin-test-helpers');
const { ZERO_ADDRESS } = constants;

const gasSpent = require('../gas-spent-helper');

const {expect} = require('chai');

const TwistedAccessControls = artifacts.require('TwistedAccessControls');
const TwistedToken = artifacts.require('TwistedToken');
const TwistedArtistCommissionRegistry = artifacts.require('TwistedArtistCommissionRegistry');
const TwistedAuctionFundSplitter = artifacts.require('TwistedAuctionFundSplitter');
const TwistedAuction = artifacts.require('TwistedAuction');

contract.only('Twisted Auction Tests', function ([
                                      creator,
                                      printingFund,
                                      bidder,
                                      ...accounts
                                  ]) {
    const baseURI = "ipfs/";
    const randIPFSHash = "QmRLHatjFTvm3i4ZtZU8KTGsBTsj3bLHLcL8FbdkNobUzm";

    // Commission splits and artists
    const commission = {
        percentages: [
            new BN(3300),
            new BN(3300),
            new BN(3400)
        ],
        artists: [
            accounts[0],
            accounts[1],
            accounts[2]
        ]
    };

    function now(){ return Math.floor( Date.now() / 1000 ) }
    function sleep(ms) {return new Promise(resolve => setTimeout(resolve, ms));}

    beforeEach(async function () {
        this.accessControls = await TwistedAccessControls.new({ from: creator });
        (await this.accessControls.isWhitelisted(creator)).should.be.true;

        this.token = await TwistedToken.new(baseURI, this.accessControls.address, { from: creator });

        this.artistCommissionRegistry = await TwistedArtistCommissionRegistry.new(this.accessControls.address, { from: creator });
        await this.artistCommissionRegistry.setCommissionSplits(commission.percentages, commission.artists, { from: creator });
        const {
            _percentages,
            _artists
        } = await this.artistCommissionRegistry.getCommissionSplits();
        expect(JSON.stringify(_percentages)).to.be.deep.equal(JSON.stringify(commission.percentages));
        expect(_artists).to.be.deep.equal(commission.artists);

        this.auctionFundSplitter = await TwistedAuctionFundSplitter.new(this.artistCommissionRegistry.address, { from: creator });

        this.auction = await TwistedAuction.new(
            this.accessControls.address,
            this.token.address,
            this.auctionFundSplitter.address
        );
    });

    describe('happy path', function () {
        beforeEach(async function () {
            ({ logs: this.logs } = await this.auction.createAuction(printingFund, now() + 2, { from: creator }));
            expectEvent.inLogs(this.logs, 'AuctionCreated', {
                _creator: creator
            });

            expect(await this.auction.currentRound()).to.be.bignumber.equal('1');
        });

        describe('bidding', function () {
            const oneEth = ether('1');

            it('should be successful with valid params', async function () {
                await sleep(2000);
                const auctionContractBalance = await balance.tracker(this.auction.address);
                const bidderBalance = await balance.tracker(bidder);

                const param = new BN('2');
                ({ logs: this.logs, receipt: this.receipt} = await this.auction.bid(param, { value: oneEth, from: bidder }));
                expectEvent.inLogs(this.logs, 'BidAccepted', {
                    _round: new BN('1'),
                    _param: param,
                    _amount: oneEth,
                    _bidder: bidder
                });

                expect(await auctionContractBalance.delta()).to.be.bignumber.equal(oneEth);
                expect(await bidderBalance.delta()).to.be.bignumber.equal(oneEth.add(gasSpent(this.receipt)).mul(new BN('-1')));
            });
        });
    });
});
