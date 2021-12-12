
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AggregatorV3Interface } from "../interfaces/AggregatorV3Interface.sol";
import { BaseMath } from "../lib/BaseMath.sol";
import { I_PpOracle } from "../interfaces/I_PpOracle.sol";


contract PpChainlinkOracle is
    Ownable,
    I_PpOracle
{
    using BaseMath for uint256;

    address public _ORACLE_;
    address public _READER_;
    uint256 public _ADJUSTMENT_;
    mapping (string => bytes32) public _MAPPING_;


    constructor(
        address oracle,
        address reader,
        string memory symbol,
        uint96 adjustmentExponent
    )
    {
        _ORACLE_ = oracle;
        _READER_ = reader;
        _ADJUSTMENT_ = 10 ** uint256(adjustmentExponent);

        bytes32 oracleAndAdjustment =
            bytes32(bytes20(oracle)) |
            bytes32(uint256(adjustmentExponent));
        _MAPPING_[symbol] = oracleAndAdjustment;
    }


    function getPrice(string calldata symbol)
        external
        view
        returns (uint256)
    {
        require(
            msg.sender == _READER_,
            "PpChainlinkOracle: Sender not authorized to get price"
        );

        bytes32 oracleAndExponent = _MAPPING_[symbol];

        require(
            oracleAndExponent != bytes32(0),
            "PpChainlinkOracle: Oracle is not set for the symbol"
        );
        (address oracle, uint256 adjustment) = getOracleAndAdjustment(oracleAndExponent);
        (
            ,
            int answer,
            ,
            ,
        ) = AggregatorV3Interface(oracle).latestRoundData();

        require(
            answer > 0,
            "PpChainlinkOracle: Invalid answer from aggregator"
        );
        uint256 rawPrice = uint256(answer);
        return rawPrice.baseMul(adjustment);
    }

    function setOracleAndAdjustment(
        address oracle,
        string calldata symbol,
        uint96 adjustmentExponent
    )
        external
        onlyOwner
    {
        bytes32 oracleAndAdjustment =
            bytes32(bytes20(oracle)) |
            bytes32(uint256(adjustmentExponent));
        _MAPPING_[symbol] = oracleAndAdjustment;
    }

    function getOracleAndAdjustment(
        bytes32 oracleAndExponent
    )
        private
        pure
        returns (address, uint256)
    {
        address oracle = address(bytes20(oracleAndExponent));
        uint256 exponent = uint256(uint96(uint256(oracleAndExponent)));
        return (oracle, 10 ** exponent);
    }
}
