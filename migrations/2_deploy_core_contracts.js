const {getAccountAddress} = require('@blockrocket/utils');

const MNEMONIC = process.env.TwistedSister_SISTERS_MNEMONIC || '';
const INFURA_KEY = process.env.TwistedSister_SISTERS_INFURA_KEY || '';

const TwistedSisterAccessControls = artifacts.require('TwistedSisterAccessControls');
const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const TwistedSisterArtistCommissionRegistry = artifacts.require('TwistedSisterArtistCommissionRegistry');
const TwistedSisterAuctionFundSplitter = artifacts.require('TwistedSisterAuctionFundSplitter');
const TwistedSisterAuction = artifacts.require('TwistedSisterAuction');

function now() { return Math.floor(Date.now() / 1000); }

module.exports = async function (deployer, network, accounts) {
    console.log('Deploying core contracts to network: ' + network);

    const creator = getAccountAddress(accounts, 0, network, MNEMONIC, INFURA_KEY);
    const auctionOwner = '0x7Edf95DEA126e5EF4Fc2FcFFc83C6Bbde82d5C54'; // no bid address
    const printingFund = '0xB2d3097580b5D1a5e352Ec9fC96566D792bc67d4';
    const baseIPFSURI = 'https://ipfs.infura.io/ipfs/';

    await deployer.deploy(TwistedSisterAccessControls, {from: creator});
    const controls = await TwistedSisterAccessControls.deployed();
    console.log('controls.address:', controls.address);

    // TODO: need to define the transfer from timestamp before launch as this will enable transfers from day 1
    const lockedUntil = now() + 86400; // 1 day
    console.log('lockedUntil', lockedUntil);

    await deployer.deploy(TwistedSisterArtistCommissionRegistry, controls.address, {from: creator});
    const registry = await TwistedSisterArtistCommissionRegistry.deployed();
    console.log('registry.address:', registry.address);

    // 50/50 split
    await registry.setCommissionSplits([5000, 5000], [accounts[1], accounts[2]]);

    await deployer.deploy(TwistedSisterAuctionFundSplitter, registry.address, {from: creator});
    const fundSplitter = await TwistedSisterAuctionFundSplitter.deployed();
    console.log('fundSplitter.address', fundSplitter.address);

    await deployer.deploy(TwistedSisterToken, baseIPFSURI, controls.address, lockedUntil, fundSplitter.address, {from: creator});
    const token = await TwistedSisterToken.deployed();
    console.log('token.address:', token.address);

    // TODO: change to nov 2, 9am CET for deployment
    const auctionStartTime = now() + 600; // start in 10 mins
    console.log('auctionStartTime', auctionStartTime);

    // Deploy contract
    await deployer.deploy(TwistedSisterAuction, controls.address, token.address, fundSplitter.address, printingFund, auctionOwner, auctionStartTime, {from: creator});
    const auction = await TwistedSisterAuction.deployed();
    console.log('auction.address:', auction.address);

    // whitelist the auction
    await controls.addWhitelisted(auction.address);

    // add TS admin
    await controls.addWhitelisted('0x08BBc983b34aafd5A1AdE5FbF0bD2B2761e0b227');

    // add AMG admin
    await controls.addWhitelisted('0x401cBf2194D35D078c0BcdAe4BeA42275483ab5F');

    // add Vince for minting support
    await controls.addWhitelisted('0x12D062B19a2DF1920eb9FC28Bd6E9A7E936de4c2');

    // Setup the commission splits
    await registry.setCommissionSplits(
        [1428, 1428, 1428, 1428, 1428, 1428, 1432],
        [
            0x96FA105210c5A7eEC1195A92D57B4eB67ab8D174,
            0xef027d257d17E640732C6fda8dDD67FcD16ff35D,
            0x52Ab9876d70F6ae0EC28e003C06d31A7698C115A,
            0x78919687191432268B8862D454d9069B3549aD9e,
            0x5F84E11e62Ec62e191e9C3BB0d401E293AbFDa72,
            0x6f22f32523bEfb4585BD515649c1fc3C612f6725,
            0xDDf31A63AC812525dd11D0D0dDF62F7AB7429E71
        ]
    );
};
