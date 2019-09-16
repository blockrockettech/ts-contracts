const { BN, constants, expectEvent, expectRevert } = require('openzeppelin-test-helpers');
const { ZERO_ADDRESS } = constants;

const { shouldBehaveLikeERC721 } = require('./ERC721.behavior');
const TwistedToken = artifacts.require('TwistedToken');

contract('ERC721', function ([_, creator, tokenOwner, anyone, auction, ...accounts]) {
    const baseURI = "ipfs";
    const randIPFSHash = "QmRLHatjFTvm3i4ZtZU8KTGsBTsj3bLHLcL8FbdkNobUzm";

    beforeEach(async function () {
        this.token = await TwistedToken.new(baseURI, auction, { from: creator });
        (await this.token.isWhitelisted(creator)).should.be.true;
        (await this.token.isWhitelisted(auction)).should.be.true;
    });

    shouldBehaveLikeERC721(creator, auction, accounts);

    describe('internal functions', function () {
        const tokenId = new BN('1');

        describe('_mint(address, uint256)', function () {
            it('reverts with a null destination address', async function () {
                await expectRevert.unspecified(this.token.createTwisted(0, 0, randIPFSHash, ZERO_ADDRESS, { from: creator }));
            });

            context('with minted token', async function () {
                beforeEach(async function () {
                    ({ logs: this.logs } = await this.token.createTwisted(0, 0, randIPFSHash, tokenOwner, { from: creator }));
                });

                it('emits a Transfer event', function () {
                    expectEvent.inLogs(this.logs, 'Transfer', { from: ZERO_ADDRESS, to: tokenOwner, tokenId });
                });

                it('creates the token', async function () {
                    (await this.token.balanceOf(tokenOwner)).should.be.bignumber.equal('1');
                    (await this.token.ownerOf(tokenId)).should.equal(tokenOwner);
                });
            });
        });
    });
});