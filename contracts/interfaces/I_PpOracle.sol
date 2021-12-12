
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;


interface I_PpOracle {

    function getPrice(string calldata symbol)
        external
        view
        returns (uint256);
}
