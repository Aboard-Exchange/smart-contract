
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { PpSettle } from "./PpSettle.sol";
import { I_PpTrader } from "../interfaces/I_PpTrader.sol";
import { PpTypes } from "../lib/PpTypes.sol";
import { SignedMath } from "../lib/SignedMath.sol";


contract PpTransaction is
    PpSettle
{
    struct TradeArg {
        uint256 takerIndex;
        uint256 makerIndex;
        string symbol;
        address trader;
        uint8 trader_style;
        bytes data;
    }


    event LogTrade(
        address indexed maker,
        address indexed taker,
        address trader,
        string symbol,
        uint256 marginAmount_maker,
        uint256 marginAmount_taker,
        uint256 positionAmount,
        bool isBuy,
        bytes32 makerBalance,
        bytes32 takerBalance
    );


    function transaction(
        address[] memory accounts,
        TradeArg[] memory trades
    )
        public
    {
        require(
            _OPERATOR_[msg.sender],
            "PpTransaction: msg.sender is not operator"
        );
        PpTypes.Context memory context = _loadContext();
        _settleAccounts(accounts); 

        for (uint256 i = 0; i < trades.length; i++) {
            TradeArg memory tradeArg = trades[i];

            require(
                _OPERATOR_[tradeArg.trader],
                "PpTransaction: trader is not operator"
            );

            address maker = accounts[tradeArg.makerIndex];
            address taker = accounts[tradeArg.takerIndex];

            _verifymaintance(maker, taker, tradeArg.trader_style, context.price);

            PpTypes.TradeResult memory tradeResult = I_PpTrader(tradeArg.trader).trade(
                maker,
                taker,
                tradeArg.data
            );

            if (tradeResult.isBuy) {
                addToMargin(maker, tradeResult.marginAmount_maker);
                subFromPosition(maker, tradeResult.positionAmount, tradeArg.symbol);
                subFromMargin(taker, tradeResult.marginAmount_taker);
                addToPosition(taker, tradeResult.positionAmount, tradeArg.symbol);
            } else {
                subFromMargin(maker, tradeResult.marginAmount_maker);
                addToPosition(maker, tradeResult.positionAmount, tradeArg.symbol);
                addToMargin(taker, tradeResult.marginAmount_taker);
                subFromPosition(taker, tradeResult.positionAmount, tradeArg.symbol);
            }

            _verifyaftertrade(maker, taker, tradeResult.isBuy, context.price, tradeArg.symbol);

            emit LogTrade(
                maker,
                taker,
                tradeArg.trader,
                tradeArg.symbol,
                tradeResult.marginAmount_maker,
                tradeResult.marginAmount_taker,
                tradeResult.positionAmount,
                tradeResult.isBuy,
                toBytes32(maker, tradeArg.symbol),
                toBytes32(taker, tradeArg.symbol)
            );
        }
    }


    function _verifymaintance(address maker, address taker, uint8 trader_style, uint256[] memory prices) private view {
        require(
            _isAboveMinMargin(taker, true, prices),
            "PpTransaction: taker is under min maintance margin before trade"
        );

        if ((trader_style == 0) && (maker != taker)) {
            require(
                _isAboveMinMargin(maker, true, prices),
                "PpTransaction: maker is under min maintance margin before trade"
            );            
        }
    }

    function _verifyaftertrade(address maker, address taker, bool taker_isBuy, uint256[] memory prices, string memory symbol) private view {
        if (!_isAboveMinMargin(taker, false, prices)) {
            if (taker_isBuy) {
                require(
                    !_BALANCE_[taker].tokenPosition[symbol].positionIsPositive,
                    "PpTransaction: taker is under min initial margin after trade"
                );
            } else {
                require(
                    _BALANCE_[taker].tokenPosition[symbol].positionIsPositive || (_BALANCE_[taker].tokenPosition[symbol].position == 0),
                    "PpTransaction: taker is under min initial margin after trade"
                );
            }
        }

        if (maker != taker) {
            if (!_isAboveMinMargin(maker, false, prices)) {
                if (taker_isBuy) {
                    require(
                        _BALANCE_[maker].tokenPosition[symbol].positionIsPositive || (_BALANCE_[maker].tokenPosition[symbol].position == 0),
                        "PpTransaction: maker is under min initial margin after trade"
                    );
                } else {
                    require(
                        !_BALANCE_[maker].tokenPosition[symbol].positionIsPositive,
                        "PpTransaction: maker is under min initial margin after trade"
                    );
                }

            }
        }
    }

}
