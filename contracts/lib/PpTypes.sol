
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;


library PpTypes {

    struct Index {
        uint32 timestamp;
        bool isPositive;
        uint128 value;
    }

    struct PositionStruct {
        bool positionIsPositive;
        uint120 position;
    }

    struct MarginStruct {
        bool marginIsPositive;
        uint120 margin;
    }

    struct Balance {
        bool marginIsPositive;
        uint120 margin;
        mapping(string => PositionStruct) tokenPosition;
    }

    struct Context {
        uint256[] price;
    }

    struct TradeResult {
        uint256 marginAmount_maker;
        uint256 marginAmount_taker;
        uint256 positionAmount;
        bool isBuy;
    }
}
