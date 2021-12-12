
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { PpState } from "./PpState.sol";
import { BaseMath } from "../lib/BaseMath.sol";
import { SignedMath } from "../lib/SignedMath.sol";
import { I_PpFunder } from "../interfaces/I_PpFunder.sol";
import { I_PpOracle } from "../interfaces/I_PpOracle.sol";
import { IndexMath } from "../lib/IndexMath.sol";
import { PpTypes } from "../lib/PpTypes.sol";


contract PpSettle is
    PpState
{
    using BaseMath for uint256;
    using SafeMath for uint256;
    using IndexMath for PpTypes.Index;
    using SignedMath for SignedMath.Int;

    uint256 private constant FLAG_MARGIN_IS_POSITIVE = 1 << (8 * 31);
    uint256 private constant FLAG_POSITION_IS_POSITIVE = 1 << (8 * 15);

    event LogIndex(
        string token,
        bytes32 index
    );

    event LogAccountSettled(
        address indexed account,
        string token,
        bool isPositive,
        uint256 amount,
        bytes32 balance
    );

    function _loadContext()
        internal
        returns (PpTypes.Context memory)
    {
        uint32 numTokens = uint32(_TOKEN_SYMBOL_.length);
        uint256[] memory price_array = new uint256[](numTokens);
        for (uint32 i = 0; i < numTokens; i++) {
            string memory token = _TOKEN_SYMBOL_[i];
            PpTypes.Index memory index = _SYMBOL_INDEX_[token];
            uint256 price = I_PpOracle(_ORACLE_).getPrice(token);
            uint256 timeDelta = block.timestamp.sub(index.timestamp);
            if (timeDelta > 0) {
                SignedMath.Int memory signedIndex = SignedMath.Int({
                    value: index.value,
                    isPositive: index.isPositive
                });
                (   bool fundingPositive,
                    uint256 fundingValue
                ) = I_PpFunder(_FUNDER_).getFunding(token, timeDelta);
                fundingValue = fundingValue.baseMul(price);
                if (fundingPositive) {
                    signedIndex = signedIndex.add(fundingValue);
                } else {
                    signedIndex = signedIndex.sub(fundingValue);
                }
                index = PpTypes.Index({
                    timestamp: uint32(block.timestamp),
                    isPositive: signedIndex.isPositive,
                    value: uint128(signedIndex.value)
                });
                _SYMBOL_INDEX_[token] = index;
            }
            price_array[i] = price;
            emit LogIndex(
                token, 
                index.toBytes32());
        }
        
        return PpTypes.Context({
            price: price_array
        });
    }

    function _settleAccounts(
        address[] memory accounts
    )
        internal
    {

        for (uint256 i = 0; i < accounts.length; i++) {
            _settleAccount(accounts[i]);
        }
    }

    function _settleAccount(
        address account
    )
        internal
    {
        uint32 numTokens = uint32(_TOKEN_SYMBOL_.length);
        for (uint32 i = 0; i < numTokens; i++) {
            string memory token = _TOKEN_SYMBOL_[i];

            PpTypes.Index memory newIndex = _SYMBOL_INDEX_[token];
            PpTypes.Index memory oldIndex = _ACCOUNT_INDEX_[token][account];

            if (oldIndex.timestamp == newIndex.timestamp) {
                continue;
            }

            _ACCOUNT_INDEX_[token][account] = newIndex;

            if (_BALANCE_[account].tokenPosition[token].position == 0) {
                continue;
            }

            SignedMath.Int memory signedIndexDiff = SignedMath.Int({
                isPositive: newIndex.isPositive,
                value: newIndex.value
            });
            if (oldIndex.isPositive) {
                signedIndexDiff = signedIndexDiff.sub(oldIndex.value);
            } else {
                signedIndexDiff = signedIndexDiff.add(oldIndex.value);
            }

            bool settlementIsPositive = signedIndexDiff.isPositive != _BALANCE_[account].tokenPosition[token].positionIsPositive;

            uint256 settlementAmount;
            if (settlementIsPositive) {
                settlementAmount = signedIndexDiff.value.baseMul(_BALANCE_[account].tokenPosition[token].position);
                addToMargin(account, settlementAmount);
            } else {
                settlementAmount = signedIndexDiff.value.baseMul(_BALANCE_[account].tokenPosition[token].position);
                subFromMargin(account, settlementAmount);
            }
            bytes32 tobyte = toBytes32(account, token);
            emit LogAccountSettled(
                account,
                token,
                settlementIsPositive,
                settlementAmount,
                tobyte
            );
        }
    }

    function _isAboveMinMargin(
        address account,
        bool maintance,
        uint256[] memory price
    )
        internal
        view
        returns (bool)
    {
        uint256 mi_margin = 0;
        SignedMath.Int memory signedMargin = SignedMath.Int({
            value: uint256(_BALANCE_[account].margin).mul(BaseMath.base()),
            isPositive: _BALANCE_[account].marginIsPositive
        });

        uint32 numTokens = uint32(_TOKEN_SYMBOL_.length);
        for (uint32 i = 0; i < numTokens; i++) {
            string memory token = _TOKEN_SYMBOL_[i];
            if (_BALANCE_[account].tokenPosition[token].position == 0) {
                continue;
            }
            uint256 positionValue = uint256(_BALANCE_[account].tokenPosition[token].position).mul(price[i]);
            SignedMath.Int memory signedpositionValue = SignedMath.Int({
                value: positionValue,
                isPositive: _BALANCE_[account].tokenPosition[token].positionIsPositive
            });

            signedMargin = signedMargin.signedAdd(signedpositionValue);
            uint256 position_minmargin = positionValue.mul(maintance? _MIN_MAINTANCE_RATE_[token]: _MIN_INITIAL_RATE_[token]);
            mi_margin = mi_margin.add(position_minmargin);
        }

        bool result;
        if (signedMargin.isPositive) {
            result = (signedMargin.value.mul(BaseMath.base()) >= mi_margin);
        } else {
            if (signedMargin.value > 0) {
                result = false;
            } else {
                result = (mi_margin == 0);
            }
        }        
        return result;
    }

    function getPosition(
        address account,
        string memory token
    )
        internal
        view
        returns (SignedMath.Int memory)
    {
        return SignedMath.Int({
            value: _BALANCE_[account].tokenPosition[token].position,
            isPositive: _BALANCE_[account].tokenPosition[token].positionIsPositive
        });
    }

    function setPosition(
        address account,
        SignedMath.Int memory newPosition,
        string memory token
    )
        internal
    {
        _BALANCE_[account].tokenPosition[token].position = uint120(newPosition.value);
        _BALANCE_[account].tokenPosition[token].positionIsPositive = newPosition.isPositive;
    }

    function addToPosition(
        address account,
        uint256 amount,
        string memory token
    )
        internal
    {
        SignedMath.Int memory signedPosition = getPosition(account, token);
        signedPosition = signedPosition.add(amount);
        setPosition(account, signedPosition, token);
    }

    function subFromPosition(
        address account,
        uint256 amount,
        string memory token
    )
        internal
    {
        SignedMath.Int memory signedPosition = getPosition(account, token);
        signedPosition = signedPosition.sub(amount);
        setPosition(account, signedPosition, token);
    }

    function addToMargin(
        address account,
        uint256 amount
    )
        internal
    {
        SignedMath.Int memory signedMargin = getMargin(account);
        signedMargin = signedMargin.add(amount);
        setMargin(account, signedMargin);
    }

    function subFromMargin(
        address account,
        uint256 amount
    )
        internal
    {
        SignedMath.Int memory signedMargin = getMargin(account);
        signedMargin = signedMargin.sub(amount);
        setMargin(account, signedMargin);
    }

    function getMargin(
        address account
    )
        internal
        view
        returns (SignedMath.Int memory)
    {
        return SignedMath.Int({
            value: _BALANCE_[account].margin,
            isPositive: _BALANCE_[account].marginIsPositive
        });
    }

    function setMargin(
        address account,
        SignedMath.Int memory newMargin
    )
        internal
    {
        _BALANCE_[account].margin = uint120(newMargin.value);
        _BALANCE_[account].marginIsPositive = newMargin.isPositive;
    }


    function toBytes32(
        address account,
        string memory token
    )
        internal
        view
        returns (bytes32)
    {
        uint256 result =
            uint256(_BALANCE_[account].tokenPosition[token].position)
            | (uint256(_BALANCE_[account].margin) << 128)
            | (_BALANCE_[account].marginIsPositive ? FLAG_MARGIN_IS_POSITIVE : 0)
            | (_BALANCE_[account].tokenPosition[token].positionIsPositive ? FLAG_POSITION_IS_POSITIVE : 0);
        return bytes32(result);
    }

    function toBytes32_margin(
        address account
    )
        internal
        view
        returns (bytes32)
    {
        uint256 result =
            uint256(_BALANCE_[account].margin)
            | (_BALANCE_[account].marginIsPositive ? FLAG_MARGIN_IS_POSITIVE : 0);
        return bytes32(result);
    }

}
