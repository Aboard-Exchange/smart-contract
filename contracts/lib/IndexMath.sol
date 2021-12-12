
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { PpTypes } from "./PpTypes.sol";


library IndexMath {

    uint256 private constant FLAG_IS_POSITIVE = 1 << (8 * 16);

    function toBytes32(
        PpTypes.Index memory index
    )
        internal
        pure
        returns (bytes32)
    {
        uint256 result =
            index.value
            | (index.isPositive ? FLAG_IS_POSITIVE : 0)
            | (uint256(index.timestamp) << 136);
        return bytes32(result);
    }
}
