// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IxCitadelLocker {
    function notifyRewardAmount(address _rewardsToken, uint256 _reward)
        external;
}
