// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISupplySchedule {
    function getMintable() external view returns (uint);
}
