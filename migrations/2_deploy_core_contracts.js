const {getAccountAddress} = require('@blockrocket/utils');

const MNEMONIC = process.env.TwistedSister_SISTERS_MNEMONIC || '';
const INFURA_KEY = process.env.TwistedSister_SISTERS_INFURA_KEY || '';

const TwistedSisterAccessControls = artifacts.require('TwistedSisterAccessControls');
const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const TwistedSisterArtistCommissionRegistry = artifacts.require('TwistedSisterArtistCommissionRegistry');
const TwistedSisterArtistFundSplitter = artifacts.require('TwistedSisterArtistFundSplitter');
const TwistedSisterAuction = artifacts.require('TwistedSisterAuction');

module.exports = async function (deployer, network, accounts) {
    console.log('Deploying core contracts to network: ' + network);

    const creator = getAccountAddress(accounts, 0, network, MNEMONIC, INFURA_KEY);
    const auctionOwner = '0x7Edf95DEA126e5EF4Fc2FcFFc83C6Bbde82d5C54'; // no bid address
    const printingFund = '0xB2d3097580b5D1a5e352Ec9fC96566D792bc67d4';
    const baseIPFSURI = 'https://ipfs.infura.io/ipfs/';

    await deployer.deploy(TwistedSisterAccessControls, {from: creator});
    const controls = await TwistedSisterAccessControls.deployed();
    console.log('controls.address:', controls.address);

    let lockedUntil = 1579820400; // 23/01/2020 @ 11:00pm (UTC)
    console.log('lockedUntil', lockedUntil);

    await deployer.deploy(TwistedSisterArtistCommissionRegistry, controls.address, {from: creator});
    const registry = await TwistedSisterArtistCommissionRegistry.deployed();
    console.log('registry.address:', registry.address);

    await deployer.deploy(TwistedSisterArtistFundSplitter, registry.address, {from: creator});
    const fundSplitter = await TwistedSisterArtistFundSplitter.deployed();
    console.log('fundSplitter.address', fundSplitter.address);

    await deployer.deploy(TwistedSisterToken, baseIPFSURI, controls.address, lockedUntil, fundSplitter.address, {from: creator});
    const token = await TwistedSisterToken.deployed();
    console.log('token.address:', token.address);

    const auctionStartTime = 1572681600; // nov 2, 9am CET
    console.log('auctionStartTime', auctionStartTime);

    // Deploy contract
    await deployer.deploy(TwistedSisterAuction, controls.address, token.address, fundSplitter.address, printingFund, auctionOwner, auctionStartTime, {from: creator});
    const auction = await TwistedSisterAuction.deployed();
    console.log('auction.address:', auction.address);

    console.log('\nwhitelisting the auction contract...');
    await controls.addWhitelisted(auction.address);
    console.log('successful!');

    console.log('\nwhitelisting the TwistedSister admin...');
    await controls.addWhitelisted('0x08BBc983b34aafd5A1AdE5FbF0bD2B2761e0b227');
    console.log('successful!');

    console.log('\nwhitelisting the AMG admin...');
    await controls.addWhitelisted('0x401cBf2194D35D078c0BcdAe4BeA42275483ab5F');
    console.log('successful!');

    console.log('\nwhitelisting the Blockrocket admin...');
    await controls.addWhitelisted('0x818Ff73A5d881C27A945bE944973156C01141232');
    console.log('successful!');

    // add Vince for minting support
    const vinceAddress = '0x12D062B19a2DF1920eb9FC28Bd6E9A7E936de4c2';
    if (creator !== vinceAddress) {
        console.log('\nwhitelisting the Vince admin...');
        await controls.addWhitelisted(vinceAddress);
        console.log('successful!');
    }

    // Setup the commission splits
    console.log('\nsetting the artists commission split in the registry...');
    await registry.setCommissionSplits(
        [1428, 1428, 1428, 1428, 1428, 1428, 1432],
        [
            '0x96FA105210c5A7eEC1195A92D57B4eB67ab8D174',
            '0xef027d257d17E640732C6fda8dDD67FcD16ff35D',
            '0x52Ab9876d70F6ae0EC28e003C06d31A7698C115A',
            '0x78919687191432268B8862D454d9069B3549aD9e',
            '0x5F84E11e62Ec62e191e9C3BB0d401E293AbFDa72',
            '0x6f22f32523bEfb4585BD515649c1fc3C612f6725',
            '0xDDf31A63AC812525dd11D0D0dDF62F7AB7429E71'
        ]
    );
    console.log('successful!');
};
