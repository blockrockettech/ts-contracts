const { BN } = require('openzeppelin-test-helpers');
const { networks } = require('../truffle-config');

const gasPriceAsBN = new BN(networks.development.gasPrice.toString());

module.exports = ({ gasUsed }) => {
    return gasPriceAsBN.mul(new BN(gasUsed.toString()));
};