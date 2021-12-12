
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { BaseMath } from "../lib/BaseMath.sol";
import { PpTypes } from "../lib/PpTypes.sol";


contract PpOrder
{
    using BaseMath for uint256;
    using SafeMath for uint256;

    struct TradeData {
        uint256 amount;
        uint256 fill_price;
        uint256 fee_maker; 
        uint256 fee_taker;
        bool isNegativeFee;
        bool maker_is_buy;
    }

    event LogOrder(
        address indexed maker,
        address indexed taker,
        uint256 amount,
        bool taker_isBuy,
        uint256 fill_price
    );

    address public _PERPETUAL_;

    constructor (
        address perpetual
    )
    {
        _PERPETUAL_ = perpetual;
    }


    function trade(
        address maker,
        address taker,
        bytes calldata data
    )
        external
        returns (PpTypes.TradeResult memory)
    {
        address perpetual = _PERPETUAL_;

        require(
            msg.sender == perpetual,
            "PpOrder: msg.sender must be Perpetual"
        );

        TradeData memory tradeData = abi.decode(data, (TradeData));

        emit LogOrder(
            maker,
            taker,
            tradeData.amount,
            !tradeData.maker_is_buy,
            tradeData.fill_price
        );

        uint256 fee_maker = tradeData.fee_maker.baseMul(tradeData.fill_price);
        uint256 fee_taker = tradeData.fee_taker.baseMul(tradeData.fill_price);

        bool isBuyOrder = tradeData.maker_is_buy;
        uint256 marginPerPosition_maker = (isBuyOrder == tradeData.isNegativeFee)
            ? tradeData.fill_price.sub(fee_maker)
            : tradeData.fill_price.add(fee_maker);
        uint256 marginPerPosition_taker = (isBuyOrder) ? tradeData.fill_price.sub(fee_taker):
                                                         tradeData.fill_price.add(fee_taker);
        return PpTypes.TradeResult({
            marginAmount_maker: tradeData.amount.baseMul(marginPerPosition_maker),
            marginAmount_taker: tradeData.amount.baseMul(marginPerPosition_taker),
            positionAmount: tradeData.amount,
            isBuy: !isBuyOrder
        });
    }
}
