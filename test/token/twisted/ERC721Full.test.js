const { BN, constants, expectEvent, expectRevert, ether, time, balance } = require('openzeppelin-test-helpers');
const {ZERO_ADDRESS} = constants;

const gasSpent = require('../../gas-spent-helper');

const {expect} = require('chai');

const {shouldBehaveLikeERC721} = require('./ERC721.behavior');
const {shouldSupportInterfaces} = require('../SupportsInterface.behavior');

const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const TwistedSisterAccessControls = artifacts.require('TwistedSisterAccessControls');
const TwistedSisterArtistCommissionRegistry = artifacts.require('TwistedSisterArtistCommissionRegistry');
const TwistedSisterArtistFundSplitter = artifacts.require('TwistedSisterArtistFundSplitter');

const oneEth = ether('1');
const oneHundred = new BN('100');

contract('ERC721 Full Test Suite for TwistedToken', function ([creator, auction, ...accounts]) {
    const name = 'twistedsister.io';
    const symbol = 'TWIST';
    const firstTokenId = new BN(1);
    const secondTokenId = new BN(2);
    const thirdTokenId = new BN(3);
    const nonExistentTokenId = new BN(999);

    const baseURI = 'ipfs/';
    const randIPFSHash = 'QmRLHatjFTvm3i4ZtZU8KTGsBTsj3bLHLcL8FbdkNobUzm';
    const tokenNotFoundRevertReason = 'Token not found for ID';

    const minter = auction;

    const [
        owner,
        newOwner,
        another,
        to,
        toAnother,
    ] = accounts;

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

    beforeEach(async function () {
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

        this.token = await TwistedSisterToken.new(baseURI, this.accessControls.address, 0, this.auctionFundSplitter.address, {from: creator});
    });

    describe('like a full ERC721', function () {
        beforeEach(async function () {
            await this.token.createTwisted(0, 1, randIPFSHash, owner, {from: minter});
            await this.token.createTwisted(1, 2, randIPFSHash, toAnother, {from: minter});
        });

        describe('mint', function () {
            it('reverts with a null destination address', async function () {
                await expectRevert.unspecified(this.token.createTwisted(0, 0, randIPFSHash, ZERO_ADDRESS, {from: creator}));
            });

            context('with minted token', async function () {
                beforeEach(async function () {
                    ({logs: this.logs} = await this.token.createTwisted(2, 3, randIPFSHash, newOwner, {from: minter}));
                });

                it('emits a Transfer and TwistMinted event', function () {
                    expectEvent.inLogs(this.logs, 'Transfer', {
                        from: ZERO_ADDRESS,
                        to: newOwner,
                        tokenId: thirdTokenId
                    });

                    expectEvent.inLogs(this.logs, 'TwistMinted', {
                        _recipient: newOwner,
                        _tokenId: thirdTokenId
                    });
                });

                it('adjusts owner tokens by index', async function () {
                    (await this.token.tokenOfOwnerByIndex(newOwner, 0)).should.be.bignumber.equal(thirdTokenId);
                });

                it('adjusts all tokens list', async function () {
                    (await this.token.tokenByIndex(2)).should.be.bignumber.equal(thirdTokenId);
                });
            });
        });

        describe('metadata', function () {
            const expectedUri = `${baseURI}${randIPFSHash}`;

            it('has a name', async function () {
                (await this.token.name()).should.be.equal(name);
            });

            it('has a symbol', async function () {
                (await this.token.symbol()).should.be.equal(symbol);
            });

            it('returns token uri', async function () {
                (await this.token.tokenURI(firstTokenId)).should.be.equal(expectedUri);
            });

            it('returns the TwistedToken\'s attributes', async function () {
                const {
                    _round,
                    _parameter,
                    _ipfsUrl
                } = await this.token.attributes(secondTokenId);

                _round.should.be.bignumber.equal(new BN('1'));
                _parameter.should.be.bignumber.equal(new BN('2'));
                _ipfsUrl.should.be.equal(expectedUri);
            });

            it('returns a token uri using updated base uri', async function () {
                const newBaseUri = 'super.ipfs/';
                const newExpectedUri = `${newBaseUri}${randIPFSHash}`;
                (await this.token.updateTokenBaseURI(newBaseUri, {from: creator}));
                (await this.token.tokenURI(firstTokenId)).should.be.equal(newExpectedUri);
            });

            it('returns a token uri using updated ipfs hash', async function () {
                const newIpfsHash = 'QmRLHatjFTvm3i4ZtZU8KTGsBTsj3bLHLcL8FbdkNobUzb';
                const newExpectedUri = `${baseURI}${newIpfsHash}`;
                (await this.token.updateIpfsHash(secondTokenId, newIpfsHash));
                (await this.token.tokenURI(secondTokenId)).should.be.equal(newExpectedUri);
            });

            it('reverts when fetching atrributes of a non-existent token', async function () {
                await expectRevert(
                    this.token.attributes(nonExistentTokenId),
                    tokenNotFoundRevertReason
                );
            });

            it('reverts when trying to update the base token URI from an unauthorised address', async function () {
                await expectRevert.unspecified(this.token.updateTokenBaseURI('', {from: another}));
            });

            it('reverts when updating base uri to a blank string', async function () {
                await expectRevert(
                    this.token.updateTokenBaseURI(''),
                    'Base URI invalid'
                );
            });

            it('reverts when trying to update the IPFS hash of a token from an unauthorised address', async function () {
                await expectRevert.unspecified(this.token.updateIpfsHash(firstTokenId, '', {from: another}));
            });

            it('reverts when updating the IPFS hash of a token to a blank string', async function () {
                await expectRevert(
                    this.token.updateIpfsHash(firstTokenId, ''),
                    'New IPFS hash invalid'
                );
            });

            it('reverts when updating the IPFS hash of a token that doesn\'t exist', async function () {
                await expectRevert(
                    this.token.updateIpfsHash(nonExistentTokenId, ''),
                    tokenNotFoundRevertReason
                );
            });

            it('reverts when querying metadata for non existent token id', async function () {
                await expectRevert.unspecified(this.token.tokenURI(nonExistentTokenId));
            });

            it('reverts if not whitelisted when calling admin functions', async function() {
                await expectRevert(
                    this.token.createTwisted(1, 1, randIPFSHash, toAnother, {from: another}),
                    "Caller not whitelisted"
                );

                await expectRevert(
                    this.token.updateTransfersEnabledFrom(1, {from: another}),
                    "Caller not whitelisted"
                );

                await expectRevert(
                    this.token.updateTokenBaseURI('', {from: another}),
                    "Caller not whitelisted"
                );

                await expectRevert(
                    this.token.updateIpfsHash(1, '', {from: another}),
                    "Caller not whitelisted"
                );

                await expectRevert(
                    this.token.updateArtistFundSplitter(this.token.address, {from: another}),
                    "Caller not whitelisted"
                );
            });
        });

        describe('tokensOfOwner', function () {
            it('returns total tokens of owner', async function () {
                const tokenIds = await this.token.tokensOfOwner(owner);
                tokenIds.length.should.equal(1);
                tokenIds[0].should.be.bignumber.equal(firstTokenId);
            });
        });

        describe('totalSupply', function () {
            it('returns total token supply', async function () {
                (await this.token.totalSupply()).should.be.bignumber.equal('2');
            });
        });

        describe('tokenOfOwnerByIndex', function () {
            describe('when the given index is lower than the amount of tokens owned by the given address', function () {
                it('returns the token ID placed at the given index', async function () {
                    (await this.token.tokenOfOwnerByIndex(owner, 0)).should.be.bignumber.equal(firstTokenId);
                });
            });

            describe('when the index is greater than or equal to the total tokens owned by the given address', function () {
                it('reverts', async function () {
                    await expectRevert.unspecified(this.token.tokenOfOwnerByIndex(owner, 2));
                });
            });

            describe('when the given address does not own any token', function () {
                it('reverts', async function () {
                    await expectRevert.unspecified(this.token.tokenOfOwnerByIndex(another, 0));
                });
            });

            describe('after transferring all tokens to another user', function () {
                beforeEach(async function () {
                    await this.token.transferFrom(owner, another, firstTokenId, {from: owner});
                    await this.token.transferFrom(toAnother, another, secondTokenId, {from: toAnother});
                });

                it('returns correct token IDs for target', async function () {
                    (await this.token.balanceOf(another)).should.be.bignumber.equal('2');
                    const tokensListed = await Promise.all(
                        [0, 1].map(i => this.token.tokenOfOwnerByIndex(another, i))
                    );
                    tokensListed.map(t => t.toNumber()).should.have.members([firstTokenId.toNumber(), secondTokenId.toNumber()]);
                });

                it('returns empty collection for original owner', async function () {
                    (await this.token.balanceOf(owner)).should.be.bignumber.equal('0');
                    await expectRevert.unspecified(this.token.tokenOfOwnerByIndex(owner, 0));
                });
            });
        });

        describe('tokenByIndex', function () {
            it('should return all tokens', async function () {
                const tokensListed = await Promise.all(
                    [0, 1].map(i => this.token.tokenByIndex(i))
                );
                tokensListed.map(t => t.toNumber()).should.have.members([firstTokenId.toNumber(), secondTokenId.toNumber()]);
            });

            it('should revert if index is greater than supply', async function () {
                await expectRevert.unspecified(this.token.tokenByIndex(2));
            });
        });

        describe('transferFrom with timelock', function () {

            function now() { return Math.floor(Date.now() / 1000); }

            let lockedUntil = -1;
            let timelockedToken;
            beforeEach(async function () {
                lockedUntil = now() + 600; // locked for  10 mins
                timelockedToken = await TwistedSisterToken.new(baseURI, this.accessControls.address, lockedUntil, this.auctionFundSplitter.address, {from: creator});

                // create one token
                await timelockedToken.createTwisted(0, 1, randIPFSHash, minter, {from: minter});
            });

            it('should revert transferFrom as still timelocked', async function () {
                await expectRevert.unspecified(timelockedToken.transferFrom(minter, newOwner, 1), {from: minter});
            });

            it('should revert safeTransferFrom as still timelocked', async function () {
                await expectRevert.unspecified(timelockedToken.safeTransferFrom(minter, newOwner, 1), {from: minter});
            });

            it('should transfer with transferFrom as past timelock', async function () {
                await time.increase(time.duration.hours(3));
                await timelockedToken.safeTransferFrom(minter, newOwner, 1, {from: minter});
            });

            it('reverts when trying to update the base token URI from an unauthorised address', async function () {
                await expectRevert.unspecified(this.token.updateTransfersEnabledFrom(0, {from: another}));
            });

            it('reverts when trying to update the base token URI from an unauthorised address', async function () {
                await this.token.updateTransfersEnabledFrom(6, {from: minter});
                (await this.token.transfersEnabledFrom()).should.be.bignumber.equal('6');
            });
        });

        describe('transferFrom secondary sales commission', function () {
            it('should split any value', async function () {
                // Balances before token transfer
                const ownerBalance = await balance.tracker(owner);
                const newOwnerBalance = await balance.tracker(newOwner);
                const anotherBalance = await balance.tracker(another);
                const toBalance = await balance.tracker(to);
                const toAnotherBalance = await balance.tracker(toAnother);

                // approve the new owner to send the value and make the tx
                const tokenOneId = 1;
                ({receipt: this.receipt} = await this.token.approve(to, tokenOneId, {from: owner}));
                const approvalGasSpent = gasSpent(this.receipt);

                ({receipt: this.receipt} = await this.token.transferFrom(owner, to, tokenOneId, {from: to, value: oneEth}));
                const transferGasSpent = gasSpent(this.receipt);

                // Assert artists correctly received 10% of the 1 ETH sent
                const singleUnitOfValue = oneEth.div(oneHundred);
                const artistShare = singleUnitOfValue.mul(new BN('10'));

                expect((await newOwnerBalance.delta())).to.be.bignumber.equal(
                    artistShare.div(oneHundred).mul(new BN('60')) // 60% of 10%
                );

                expect((await anotherBalance.delta())).to.be.bignumber.equal(
                    artistShare.div(oneHundred).mul(new BN('40')) // 40% of 10%
                );

                // Assert twist token hodlers received the correct amount of ETH
                expect(await this.token.tokenIdPointer()).to.be.bignumber.equal(new BN('2'));
                const tokenHodlersShare = singleUnitOfValue.mul(new BN('20'));
                const individualHodlerShare = tokenHodlersShare.div(new BN('2'));

                expect(await toAnotherBalance.delta()).to.be.bignumber.equal(individualHodlerShare);

                expect(await toBalance.delta()).to.be.bignumber.equal(
                    oneEth.add(transferGasSpent).sub(individualHodlerShare).mul(new BN('-1'))
                );

                // Assert original owner should have received 70% - minus approval gas
                const sellerShare = singleUnitOfValue.mul(new BN('70'));
                expect(await ownerBalance.delta()).to.be.bignumber.equal(sellerShare.sub(approvalGasSpent));
            });
        });
    });

    shouldBehaveLikeERC721(creator, minter, accounts);

    shouldSupportInterfaces([
        'ERC165',
        'ERC721',
        'ERC721Enumerable',
        'ERC721Metadata',
    ]);
});
