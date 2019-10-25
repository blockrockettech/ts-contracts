const { getAccountAddress } = require('@blockrocket/utils');

const MNEMONIC = process.env.TWISTED_SISTERS_MNEMONIC || '';
const INFURA_KEY = process.env.TWISTED_SISTERS_INFURA_KEY || '';

const TwistedAccessControls = artifacts.require('TwistedAccessControls');
const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const TwistedArtistCommissionRegistry = artifacts.require('TwistedArtistCommissionRegistry');
const TwistedAuctionFundSplitter = artifacts.require('TwistedAuctionFundSplitter');
const TwistedAuction = artifacts.require('TwistedAuction');

function now(){ return Math.floor( Date.now() / 1000 ) }

module.exports = async function (deployer, network, accounts) {
    console.log("Deploying core contracts to network: " + network);

    const creator = getAccountAddress(accounts, 0, network, MNEMONIC, INFURA_KEY);
    const auctionOwner = '0x7Edf95DEA126e5EF4Fc2FcFFc83C6Bbde82d5C54'; // no bid address
    const printingFund = '0xB2d3097580b5D1a5e352Ec9fC96566D792bc67d4';
    const baseIPFSURI = 'https://ipfs.infura.io/ipfs/';

    await deployer.deploy(TwistedAccessControls, { from: creator });
    const controls = await TwistedAccessControls.deployed();
    console.log('controls.address:', controls.address);

    //todo: need to define the transfer from timestamp before launch as this will enable transfers from day 1
    await deployer.deploy(TwistedSisterToken, baseIPFSURI, controls.address, 0, { from: creator });
    const token = await TwistedSisterToken.deployed();
    console.log('token.address:', token.address);

    await deployer.deploy(TwistedArtistCommissionRegistry, controls.address, { from: creator });
    const registry = await TwistedArtistCommissionRegistry.deployed();
    console.log('registry.address:', registry.address);

    await deployer.deploy(TwistedAuctionFundSplitter, registry.address, { from: creator });
    const fundSplitter = await TwistedAuctionFundSplitter.deployed();
    console.log('fundSplitter.address', fundSplitter.address);

    // todo: change to nov 2, 9am CET for deployment
    const auctionStartTime = now() + 600; // start in 10 mins
    console.log('auctionStartTime', auctionStartTime);

    // Deploy mock contract to test net
    await deployer.deploy(TwistedAuction,
        controls.address, token.address, fundSplitter.address, printingFund, auctionOwner, auctionStartTime,
        {
            from: creator
        });
    const auction = await TwistedAuction.deployed();
    console.log('auction.address:', auction.address);
};
