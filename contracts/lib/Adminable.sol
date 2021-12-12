
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.9;
pragma abicoder v2;


contract Adminable {

    bytes32 internal constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);


    modifier onlyAdmin() {
        require(
            msg.sender == getAdmin(),
            "Adminable: not admin"
        );
        _;
    }

    function getAdmin()
        public
        view
        returns (address)
    {
        return address(uint160(uint256(load(ADMIN_SLOT))));
    }

    function load(
        bytes32 slot
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 result;
        assembly {
            result := sload(slot)
        }
        return result;
    }

}
