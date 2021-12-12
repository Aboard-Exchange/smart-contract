
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { PpState } from "./PpState.sol";
import { PpTypes } from "../lib/PpTypes.sol";


contract PpSet is PpState {
    
    event LogSetOperator(
        address operator,
        bool approved
    );

    event LogSetToken(
        address token_address
    );

    event LogSetOracle(
        address oracle
    );

    event LogSetFunder(
        address funder
    );

    event LogSetMinInitialRate(
        uint256 minCollateral
    );

    event LogSetMinMaintanceRate(
        uint256 minCollateral
    );
    
    event LogSetSymbolIndexInitial(
        string symbol,
        uint32 timestamp
    );

    event LogSetTokenSymbolInitial(
        string [] token_symbol
    );


    function setOperator(
        address operator,
        bool approved
    )
        external
        onlyAdmin
    {
        _OPERATOR_[operator] = approved;
        emit LogSetOperator(operator, approved);
    }

    function setToken(
        address token_address
    )
        external
        onlyAdmin
    {
        _TOKEN_ = token_address;
        emit LogSetToken(token_address);
    }

    function setOracle(
        address oracle
    )
        external
        onlyAdmin
    {
        _ORACLE_ = oracle;
        emit LogSetOracle(oracle);
    }

    function setFunder(
        address funder
    )
        external
        onlyAdmin
    {
        _FUNDER_ = funder;
        emit LogSetFunder(funder);
    }

    function setMinInitialRate(
        string calldata symbol,
        uint256 minCollateral
    )
        external
        onlyAdmin
    {
        _MIN_INITIAL_RATE_[symbol] = minCollateral;
        emit LogSetMinInitialRate(minCollateral);
    }

    function setMinMaintanceRate(
        string calldata symbol,
        uint256 minCollateral
    )
        external
        onlyAdmin
    {
        _MIN_MAINTANCE_RATE_[symbol] = minCollateral;
        emit LogSetMinMaintanceRate(minCollateral);
    }

    function setSymbolIndexInitial(
        string calldata symbol
    )
        external
        onlyAdmin
    {
        _SYMBOL_INDEX_[symbol] = PpTypes.Index({
            timestamp: uint32(block.timestamp),
            isPositive: false,
            value: 0
        });
        emit LogSetSymbolIndexInitial(symbol, uint32(block.timestamp));
    }

    function setTokenSymbolInitial(
        string[] calldata symbol_array
    )
        external
        onlyAdmin
    {
        _TOKEN_SYMBOL_ = new string[](symbol_array.length);
        for (uint256 i = 0; i < symbol_array.length; i++) {
            _TOKEN_SYMBOL_[i] = symbol_array[i];
        }
        emit LogSetTokenSymbolInitial(_TOKEN_SYMBOL_);
    }
}
