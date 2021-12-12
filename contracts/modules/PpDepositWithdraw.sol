
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { PpSettle } from "./PpSettle.sol";
import { PpTypes } from "../lib/PpTypes.sol";
import { SignedMath } from "../lib/SignedMath.sol";


contract PpDepositWithdraw is
    PpSettle
{

    event LogDeposit(
        address indexed account,
        uint256 amount,
        bytes32 margin
    );

    event LogWithdraw(
        address indexed account,
        address destination,
        uint256 amount,
        bytes32 margin
    );


    function deposit(
        address account,
        uint256 amount
    )
        external
        nonReentrant
    {
        _loadContext();
        _settleAccount(account);
        
        SafeERC20.safeTransferFrom(
            IERC20(_TOKEN_),
            msg.sender,
            address(this),
            amount
        );

        addToMargin(account, amount);

        emit LogDeposit(
            account,
            amount,
            toBytes32_margin(account)
        );
    }


    function withdraw(
        address account,
        address destination,
        uint256 amount
    )
        external
        nonReentrant
    {   
        require(
            account == msg.sender || _OPERATOR_[msg.sender],
            "withdraw: no permission to withdraw"
        );

        PpTypes.Context memory context = _loadContext();
        _settleAccount(account);
        
        SafeERC20.safeTransfer(
            IERC20(_TOKEN_),
            destination,
            amount
        );

        subFromMargin(account, amount);

        require(
            _isAboveMinMargin(account, false, context.price),
            "withdraw: under minimum initial margin"
        );

        emit LogWithdraw(
            account,
            destination,
            amount,
            toBytes32_margin(account)
        );
    }
}
