#!/usr/bin/env bash

node ./node_modules/.bin/truffle-flattener ./contracts/TwistedSisterAuction.sol > ./flat/TwistedSisterAuction.sol;
node ./node_modules/.bin/truffle-flattener ./contracts/TwistedSister3DAuction.sol > ./flat/TwistedSister3DAuction.sol;
node ./node_modules/.bin/truffle-flattener ./contracts/token/TwistedSister3DToken.sol > ./flat/TwistedSister3DToken.sol;
