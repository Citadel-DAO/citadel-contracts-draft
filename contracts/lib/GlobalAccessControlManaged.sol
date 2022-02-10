// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin-contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../../interfaces/IGac.sol";

/**
Supply schedules are defined in terms of Epochs

Epoch {
    Total Mint
    Start time
    Duration
    End time (implicit)
}
*/
contract GlobalAccessControlManaged is PausableUpgradeable {
    IGac public gac;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    function __GlobalAccessControlManaged_init(address _globalAccessControl)
        public
        initializer
    {
        __Pausable_init_unchained();
        gac = IGac(_globalAccessControl);
    }

    modifier onlyRole(bytes32 role) {
        require(gac.hasRole(role, msg.sender), "invalid-caller-role");
        _;
    }

    /// @dev can be pausable by GAC or local flag
    modifier gacPausable() {
        require(gac.paused() == false, "global-paused");
        require(paused() == false, "local-paused");
        _;
    }

    function pause() external {
        require(gac.hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() external {
        require(gac.hasRole(UNPAUSER_ROLE, msg.sender));
        _unpause();
    }
}
