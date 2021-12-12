
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { PpTypes } from "../lib/PpTypes.sol";

interface I_PpTrader {

    function trade(
        address maker,
        address taker,
        bytes calldata data
    )
        external
        returns (PpTypes.TradeResult memory);
}
