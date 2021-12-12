
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { Adminable } from "../lib/Adminable.sol";
import { ReentrancyGuard } from "../lib/ReentrancyGuard.sol";
import { PpTypes } from "../lib/PpTypes.sol";


contract PpState is
    Adminable,
    ReentrancyGuard
{
    string[] internal _TOKEN_SYMBOL_;

    mapping(address => PpTypes.Balance) internal _BALANCE_;

    mapping(address => bool) internal _OPERATOR_;

    address internal _TOKEN_;
    address internal _ORACLE_;
    address internal _FUNDER_;

    mapping(string => PpTypes.Index) internal _SYMBOL_INDEX_;
    mapping(string => mapping(address => PpTypes.Index)) internal _ACCOUNT_INDEX_;
    
    mapping(string => uint256) internal _MIN_INITIAL_RATE_;
    mapping(string => uint256) internal _MIN_MAINTANCE_RATE_;

}
