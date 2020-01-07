const {getAccountAddress} = require('@blockrocket/utils');

const MNEMONIC = process.env.TWISTED_SISTERS_MNEMONIC || '';
const INFURA_KEY = process.env.TWISTED_SISTERS_INFURA_KEY || '';

const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const BuyNowNFTMarketplace = artifacts.require('BuyNowNFTMarketplace');

module.exports = async function (deployer, network, accounts) {
    console.log(`Deploying the buy now NFT marketplace on [${network}]`);

    const token = await TwistedSisterToken.deployed();
    console.log('token.address', token.address);

    const creator = getAccountAddress(accounts, 0, network, MNEMONIC, INFURA_KEY);

    await deployer.deploy(BuyNowNFTMarketplace, token.address, { from: creator });
    const marketplace = await BuyNowNFTMarketplace.deployed();
    console.log('marketplace', marketplace.address);
};