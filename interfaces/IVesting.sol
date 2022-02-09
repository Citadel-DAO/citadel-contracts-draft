// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVesting {
    function setupVesting (address recipient,
        uint256 _amount,
        uint256 _unlockBegin) external;
}