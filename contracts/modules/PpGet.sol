
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { PpState } from "./PpState.sol";
import { I_PpOracle } from "../interfaces/I_PpOracle.sol";
import { PpTypes } from "../lib/PpTypes.sol";


contract PpGet is PpState {

    function getAccountBalance(
        address account,
        string calldata symbol
    )
        external
        view
        returns (PpTypes.PositionStruct memory)
    {
        return _BALANCE_[account].tokenPosition[symbol];
    }

    function getAccountMargin(
        address account
    )
        external
        view
        returns (PpTypes.MarginStruct memory)
    {
        return PpTypes.MarginStruct({
            marginIsPositive: _BALANCE_[account].marginIsPositive,
            margin: _BALANCE_[account].margin
        });
    }

    function getAccountIndex(
        address account,
        string calldata symbol
    )
        external
        view
        returns (PpTypes.Index memory)
    {
        return _ACCOUNT_INDEX_[symbol][account];
    }


    function getIsOperator(
        address operator
    )
        external
        view
        returns (bool)
    {
        return _OPERATOR_[operator];
    }

    function getTokenContract()
        external
        view
        returns (address)
    {
        return _TOKEN_;
    }

    function getOracleContract()
        external
        view
        returns (address)
    {
        return _ORACLE_;
    }

    function getFunderContract()
        external
        view
        returns (address)
    {
        return _FUNDER_;
    }

    function getSymbolIndex(
        string calldata token
    )
        external
        view
        returns (PpTypes.Index memory)
    {
        return _SYMBOL_INDEX_[token];
    }

    function getMinInitialRate(string calldata symbol)
        external
        view
        returns (uint256)
    {
        return _MIN_INITIAL_RATE_[symbol];
    }

    function getMinMaintanceRate(string calldata symbol)
        external
        view
        returns (uint256)
    {
        return _MIN_MAINTANCE_RATE_[symbol];
    }

    function getSymbolArray()
        external
        view
        returns (string [] memory)
    {
        return _TOKEN_SYMBOL_;
    }

}
