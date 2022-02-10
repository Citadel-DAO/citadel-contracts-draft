// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./lib/GlobalAccessControlManaged.sol";

/**
Supply schedules are defined in terms of Epochs

Epoch {
    Total Mint
    Start time
    Duration
    End time (implicit)
}
*/
contract SupplySchedule is GlobalAccessControlManaged {
    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");

    struct SupplyEpoch {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 duration;
    }

    function initialize(address _gac) public initializer {
        __GlobalAccessControlManaged_init(_gac);
    }

    /// @dev Add emissions epoch. It is possible to have overlapping epochs.
    /// TODO base the epoch logic off of the tree schedule logic.
    function addEpoch(
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 duration
    ) external onlyRole(CONTRACT_GOVERNANCE_ROLE) gacPausable {}

    /// @dev Modify an existing epoch unilaterally. Past mint actions will not be affected
    function modifyEpoch(
        uint256 id,
        uint256 amount,
        uint256 startTime,
        uint256 endTime,
        uint256 duration
    ) external onlyRole(CONTRACT_GOVERNANCE_ROLE) gacPausable {}

    function getMintable() external view returns (uint256) {
        return 0;
    }
}
