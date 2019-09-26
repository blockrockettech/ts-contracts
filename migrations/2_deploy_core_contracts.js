const HDWalletProvider = require('@truffle/hdwallet-provider');

const MNEMONIC = process.env.TWISTED_SISTERS_MNEMONIC || '';
const INFURA_KEY = process.env.TWISTED_SISTERS_INFURA_KEY || '';

const TwistedAccessControls = artifacts.require('TwistedAccessControls');
const TwistedSisterToken = artifacts.require('TwistedSisterToken');
const TwistedArtistCommissionRegistry = artifacts.require('TwistedArtistCommissionRegistry');
const TwistedAuctionFundSplitter = artifacts.require('TwistedAuctionFundSplitter');
const TwistedAuctionMock = artifacts.require('TwistedAuctionMock');
const TwistedAuction = artifacts.require('TwistedAuction');

function getAccountAddress(accounts, index, network) {
    let addr = accounts[index];
    if (network === 'ropsten' || network === 'rinkeby') {
        addr = new HDWalletProvider(MNEMONIC, `https://${network}.infura.io/v3/${INFURA_KEY}`, index).getAddress();
    }
    console.log(`Using account [${addr}] for network [${network}]`);
    return addr;
}
function now(){ return Math.floor( Date.now() / 1000 ) }
module.exports = async function (deployer, network, accounts) {
    console.log("Deploying core contracts to network: " + network);

    const creator = getAccountAddress(accounts, 0, network);
    const printingFund = getAccountAddress(accounts, 1, network);
    const baseIPFSURI = 'ipfs.io/ipns/';

    await deployer.deploy(TwistedAccessControls, { from: creator });
    const controls = await TwistedAccessControls.deployed();
    console.log('controls.address:', controls.address);

    await deployer.deploy(TwistedSisterToken, baseIPFSURI, controls.address, { from: creator });
    const token = await TwistedSisterToken.deployed();
    console.log('token.address:', token.address);

    await deployer.deploy(TwistedArtistCommissionRegistry, controls.address, { from: creator });
    const registry = await TwistedArtistCommissionRegistry.deployed();
    console.log('registry.address:', registry.address);

    await deployer.deploy(TwistedAuctionFundSplitter, registry.address, { from: creator });
    const fundSplitter = await TwistedAuctionFundSplitter.deployed();
    console.log('fundSplitter.address', fundSplitter.address);

    if(network.toString() === 'live') {
        // todo: change to nov 2, 8am for deployment
        const auctionStartTime = now() + 5;
        console.log('auctionStartTime', auctionStartTime);

        await deployer.deploy(TwistedAuction,
            controls.address, token.address, fundSplitter.address, printingFund, auctionStartTime,
            {
                from: creator
            });
        const auction = await TwistedAuction.deployed();
        console.log('auction.address:', auction.address);
    } else {
        const auctionStartTime = now() + 600; // start in 10 mins
        console.log('auctionStartTime', auctionStartTime);

        // Deploy mock contract to test net
        await deployer.deploy(TwistedAuctionMock,
            controls.address, token.address, fundSplitter.address, printingFund, auctionStartTime,
            {
                from: creator
            });
        const auction = await TwistedAuctionMock.deployed();
        console.log('auction.address:', auction.address);
    }
};