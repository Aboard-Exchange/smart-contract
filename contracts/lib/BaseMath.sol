
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";


library BaseMath {
    using SafeMath for uint256;

    uint256 constant internal BASE = 10 ** 18;

    function base()
        internal
        pure
        returns (uint256)
    {
        return BASE;
    }

    function baseMul(
        uint256 value,
        uint256 baseValue
    )
        internal
        pure
        returns (uint256)
    {
        return value.mul(baseValue).div(BASE);
    }

    function min(
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

}
