const {getAccountAddress} = require('@blockrocket/utils');

const MNEMONIC = process.env.TWISTED_SISTERS_MNEMONIC || '';
const INFURA_KEY = process.env.TWISTED_SISTERS_INFURA_KEY || '';

const TwistedSisterAccessControls = artifacts.require('TwistedSisterAccessControls');
const TwistedSisterArtistFundSplitter = artifacts.require('TwistedSisterArtistFundSplitter');
const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const TwistedSister3DToken = artifacts.require('TwistedSister3DToken');
const TwistedSister3DAuction = artifacts.require('TwistedSister3DAuction');

module.exports = async function (deployer, network, accounts) {
    console.log('Deploying TWIST3D contracts to network', network);

    const creator = getAccountAddress(accounts, 0, network, MNEMONIC, INFURA_KEY);
    const baseIPFSURI = 'https://ipfs.infura.io/ipfs/';
    const fromCreator = { from: creator };
    console.log('creator', creator);

    // fetch previously deployed contracts
    const accessControls = await TwistedSisterAccessControls.deployed();
    const artistFundSplitter = await TwistedSisterArtistFundSplitter.deployed();
    const token = await TwistedSisterToken.deployed();

    await deployer.deploy(TwistedSister3DToken,
        baseIPFSURI,
        accessControls.address,
        artistFundSplitter.address,
        token.address,
    fromCreator);
    const token3d = await TwistedSister3DToken.deployed();
    console.log('3D token address', token3d.address);

    await deployer.deploy(TwistedSister3DAuction,
        accessControls.address,
        token3d.address,
        artistFundSplitter.address,
        token.address,
    fromCreator);
    const auction3d = await TwistedSister3DAuction.deployed();
    console.log('auction3d.address', auction3d.address);

    console.log('\nwhitelisting the 3d auction contract...');
    await accessControls.addWhitelisted(auction3d.address, fromCreator);
    console.log('successful!');
};