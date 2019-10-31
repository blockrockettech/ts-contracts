pragma solidity ^0.5.12;

library Strings {

    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function doConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            bab[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            bab[k++] = _bb[i];
        }
        return string(bab);
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return doConcat(_a, _b);
    }
}
