
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { PpSet } from "./modules/PpSet.sol";
import { PpSettle } from "./modules/PpSettle.sol";
import { PpGet } from "./modules/PpGet.sol";
import { PpDepositWithdraw } from "./modules/PpDepositWithdraw.sol";
import { PpTransaction } from "./modules/PpTransaction.sol";


contract Perpetual is
    PpSet,
    PpGet,
    PpDepositWithdraw,
    PpTransaction
{}
