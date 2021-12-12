
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;


interface I_PpFunder {
    function getFunding(
        string calldata symbol,
        uint256 timeDelta
    )
        external
        view
        returns (bool, uint256);
}
