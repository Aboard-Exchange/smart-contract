
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { BaseMath } from "../lib/BaseMath.sol";
import { PpGet } from "../modules/PpGet.sol";
import { PpTypes } from "../lib/PpTypes.sol";


contract PpLiquidate
{
    using SafeMath for uint256;
    using BaseMath for uint256;

    struct TradeData {
        uint256 fee_liquidatee;
        uint256 fee_liquidator;
        bool neg_fee_liquidator;
        uint256 price_liq;
        string symbol;
        uint256 amount;
    }

    event LogLiquidate(
        address indexed maker,
        address indexed taker,
        uint256 amount,
        bool isBuy,
        uint256 liqPrice
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
            "PpLiquidate: msg.sender must be Perpetual"
        );

        TradeData memory tradeData = abi.decode(data, (TradeData));
        PpTypes.PositionStruct memory makerPosition = PpGet(perpetual).getAccountBalance(maker, tradeData.symbol);

        uint256 amount = BaseMath.min(tradeData.amount, uint256(makerPosition.position));

        bool isBuyOrder = !makerPosition.positionIsPositive;
        emit LogLiquidate(
            maker,
            taker,
            amount,
            isBuyOrder,
            tradeData.price_liq
        );

        uint256 fee_maker = tradeData.fee_liquidatee.baseMul(tradeData.price_liq);
        uint256 fee_taker = tradeData.fee_liquidator.baseMul(tradeData.price_liq);

        uint256 marginPerPosition_taker = (isBuyOrder == tradeData.neg_fee_liquidator)
            ? tradeData.price_liq.sub(fee_taker)
            : tradeData.price_liq.add(fee_taker);
        uint256 marginPerPosition_maker = (isBuyOrder) ? tradeData.price_liq.sub(fee_maker):
                                                         tradeData.price_liq.add(fee_maker);

        return PpTypes.TradeResult({
            marginAmount_maker: amount.baseMul(marginPerPosition_maker),
            marginAmount_taker: amount.baseMul(marginPerPosition_taker),
            positionAmount: amount,
            isBuy: !isBuyOrder
        });
    }
}
