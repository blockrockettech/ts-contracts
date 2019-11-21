const { BN, constants, expectEvent, expectRevert, ether, balance } = require('openzeppelin-test-helpers');

const TwistedSisterAccessControls = artifacts.require('TwistedSisterAccessControls');
const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const TwistedSister3DToken = artifacts.require('TwistedSister3DToken');
const TwistedSisterArtistCommissionRegistry = artifacts.require('TwistedSisterArtistCommissionRegistry');
const TwistedSisterArtistFundSplitter = artifacts.require('TwistedSisterArtistFundSplitter');
const TwistedSister3DAuction = artifacts.require('TwistedSister3DAuction');

contract.only('Twisted 3D Auction Tests', function ([
                                                creator,
                                                ...accounts
                                            ]) {
    const fromCreator = { from: creator };

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

    const baseURI = "ipfs/";
    const randIPFSHash = "QmRLHatjFTvm3i4ZtZU8KTGsBTsj3bLHLcL8FbdkNobUzm";

    const minBid = ether('0.02');
    const halfEth = ether('0.5');
    const oneEth = ether('1');
    const justOverOneEth = ether('1.01');
    const oneHalfEth = ether('1.5');

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
    });
});