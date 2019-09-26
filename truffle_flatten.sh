#!/usr/bin/env bash

node ./node_modules/.bin/truffle-flattener ./contracts/Migrations.sol > ./contracts-flat/Migrations.sol;

node ./node_modules/.bin/truffle-flattener ./contracts/splitters/TwistedAuctionFundSplitter.sol > ./contracts-flat/splitters/TwistedAuctionFundSplitter.sol;
node ./node_modules/.bin/truffle-flattener ./contracts/TwistedAccessControls.sol > ./contracts-flat/TwistedAccessControls.sol;
node ./node_modules/.bin/truffle-flattener ./contracts/TwistedArtistCommissionRegistry.sol > ./contracts-flat/TwistedArtistCommissionRegistry.sol;
node ./node_modules/.bin/truffle-flattener ./contracts/token/TwistedSisterToken.sol > ./contracts-flat/token/TwistedSisterToken.sol;
node ./node_modules/.bin/truffle-flattener ./contracts/mock/TwistedAuctionMock.sol > ./contracts-flat/mock/TwistedAuctionMock.sol;
node ./node_modules/.bin/truffle-flattener ./contracts/TwistedAuction.sol > ./contracts-flat/TwistedAuction.sol;
