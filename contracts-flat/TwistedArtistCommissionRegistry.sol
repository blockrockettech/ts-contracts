
// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/interfaces/ITwistedArtistCommissionRegistry.sol

pragma solidity ^0.5.0;

contract ITwistedArtistCommissionRegistry {
    function getCommissionSplits() external view returns (uint256[] memory _percentages, address payable[] memory _artists);
    function getMaxCommission() external view returns (uint256);
}

// File: contracts/interfaces/ITwistedAccessControls.sol

pragma solidity ^0.5.0;

contract ITwistedAccessControls {
    function isWhitelisted(address account) public view returns (bool);

    function isWhitelistAdmin(address account) public view returns (bool);
}

// File: contracts/TwistedArtistCommissionRegistry.sol

pragma solidity ^0.5.0;




contract TwistedArtistCommissionRegistry is ITwistedArtistCommissionRegistry {
    using SafeMath for uint256;

    ITwistedAccessControls public accessControls;

    address payable[] public artists;

    uint256 public maxCommission = 10000;

    // Artist address <> commission percentage
    mapping(address => uint256) public artistCommissionSplit;

    modifier isWhitelisted() {
        require(accessControls.isWhitelisted(msg.sender), "Caller not whitelisted");
        _;
    }

    constructor(ITwistedAccessControls _accessControls) public {
        accessControls = _accessControls;
    }

    function setCommissionSplits(uint256[] calldata _percentages, address payable[] calldata _artists) external isWhitelisted returns (bool) {
        require(_percentages.length == _artists.length, "Differing percentage or recipient sizes");

        // reset any existing splits
        for(uint256 i = 0; i < artists.length; i++) {
            address payable artist = artists[i];
            delete artistCommissionSplit[artist];
            delete artists[i];
        }
        artists.length = 0;

        uint256 total;

        for(uint256 i = 0; i < _artists.length; i++) {
            address payable artist = _artists[i];
            require(artist != address(0x0), "Invalid address");
            artists.push(artist);
            artistCommissionSplit[artist] = _percentages[i];
            total = total.add(_percentages[i]);
        }

        require(total == maxCommission, "Total commission does not match allowance");

        return true;
    }

    function getCommissionSplits() external view returns (uint256[] memory _percentages, address payable[] memory _artists) {
        require(artists.length > 0, "No artists have been registered");
        _percentages = new uint256[](artists.length);
        _artists = new address payable[](artists.length);

        for(uint256 i = 0; i < artists.length; i++) {
            address payable artist = artists[i];
            _percentages[i] = artistCommissionSplit[artist];
            _artists[i] = artist;
        }
    }

    function getMaxCommission() external view returns (uint256) {
        return maxCommission;
    }
}
