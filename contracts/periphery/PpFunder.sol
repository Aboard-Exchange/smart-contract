
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { BaseMath } from "../lib/BaseMath.sol";
import { SignedMath } from "../lib/SignedMath.sol";
import { I_PpFunder } from "../interfaces/I_PpFunder.sol";
import { IndexMath } from "../lib/IndexMath.sol";
import { PpTypes } from "../lib/PpTypes.sol";


contract PpFunder is
    Ownable,
    I_PpFunder
{
    using BaseMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint256;
    using IndexMath for PpTypes.Index;
    using SignedMath for SignedMath.Int;


    uint256 private constant FLAG_IS_POSITIVE = 1 << 128;
    uint128 constant internal BASE = 10 ** 18;

    uint128 public constant MAX_ABS_VALUE = BASE * 75 / 10000 / (8 hours);
    uint128 public constant MAX_ABS_DIFF_PER_SECOND = MAX_ABS_VALUE * 2 / (45 minutes);


    event LogFundingRateUpdated(
        bytes32 fundingRate
    );

    event LogFundingRateProviderSet(
        address fundingRateProvider
    );


    mapping(string => PpTypes.Index) private _FUNDING_RATE_;

    address public _FUNDING_RATE_PROVIDER_;


    constructor(
        address fundingRateProvider
    )
    {
        PpTypes.Index memory fundingRate = PpTypes.Index({
            timestamp: uint32(block.timestamp),
            isPositive: true,
            value: 0
        });
        _FUNDING_RATE_PROVIDER_ = fundingRateProvider;

        emit LogFundingRateUpdated(fundingRate.toBytes32());
        emit LogFundingRateProviderSet(fundingRateProvider);
    }

    function setFundingRate(
        string calldata symbol,
        SignedMath.Int calldata newRate
    )
        external
        returns (PpTypes.Index memory)
    {
        require(
            msg.sender == _FUNDING_RATE_PROVIDER_,
            "PpFunder: funding rate can only be set by the provider"
        );

        SignedMath.Int memory boundedNewRate = _boundRate(symbol, newRate);
        PpTypes.Index memory boundedNewRateWithTimestamp = PpTypes.Index({
            timestamp: uint32(block.timestamp),
            isPositive: boundedNewRate.isPositive,
            value: uint128(boundedNewRate.value)
        });
        _FUNDING_RATE_[symbol] = boundedNewRateWithTimestamp;

        emit LogFundingRateUpdated(boundedNewRateWithTimestamp.toBytes32());

        return boundedNewRateWithTimestamp;
    }

    function setFundingRateProvider(
        address newProvider
    )
        external
        onlyOwner
    {
        _FUNDING_RATE_PROVIDER_ = newProvider;
        emit LogFundingRateProviderSet(newProvider);
    }


    function getFunding(
        string memory symbol,
        uint256 timeDelta
    )
        public
        view
        returns (bool, uint256)
    {
        PpTypes.Index memory fundingRate = _FUNDING_RATE_[symbol];
        uint256 fundingAmount = uint256(fundingRate.value).mul(timeDelta);
        return (fundingRate.isPositive, fundingAmount);
    }


    function _boundRate(
        string memory symbol,
        SignedMath.Int memory newRate
    )
        private
        view
        returns (SignedMath.Int memory)
    {
        PpTypes.Index memory oldRateWithTimestamp = _FUNDING_RATE_[symbol];
        SignedMath.Int memory oldRate = SignedMath.Int({
            value: oldRateWithTimestamp.value,
            isPositive: oldRateWithTimestamp.isPositive
        });

        uint256 timeDelta = block.timestamp.sub(oldRateWithTimestamp.timestamp);
        uint256 maxDiff = MAX_ABS_DIFF_PER_SECOND.mul(timeDelta);

        if (newRate.gt(oldRate)) {
            SignedMath.Int memory upperBound = SignedMath.min(
                oldRate.add(maxDiff),
                SignedMath.Int({ value: MAX_ABS_VALUE, isPositive: true })
            );
            return SignedMath.min(
                newRate,
                upperBound
            );
        } else {
            SignedMath.Int memory lowerBound = SignedMath.max(
                oldRate.sub(maxDiff),
                SignedMath.Int({ value: MAX_ABS_VALUE, isPositive: false })
            );
            return SignedMath.max(
                newRate,
                lowerBound
            );
        }
    }
}
