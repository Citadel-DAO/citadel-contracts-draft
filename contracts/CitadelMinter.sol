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

import "../interfaces/citadel/ISupplySchedule.sol";
import "../interfaces/citadel/ICitadelToken.sol";
import "../interfaces/citadel/IxCitadel.sol";
import "../interfaces/citadel/IxCitadelLocker.sol";

/**
Supply schedules are defined in terms of Epochs

Epoch {
    Total Mint
    Start time
    Duration
    End time (implicit)
}
*/
contract CitadelMinter is GlobalAccessControlManaged {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");
    bytes32 public constant POLICY_OPERATIONS_ROLE =
        keccak256("POLICY_OPERATIONS_ROLE");

    address public citadelToken;
    address public xCitadel;
    // The minted tokens allocated to funding will be sent to the policy operations manager
    address public policyDestination;
    ISupplySchedule public supplySchedule;
    IxCitadelLocker public xCitadelLocker;

    uint256 constant MAX_BPS = 10000;

    event SupplyScheduleSet(ISupplySchedule supplySchedule);

    function initialize(
        address _gac,
        address _supplySchedule,
        address _citadelToken,
        address _xCitadel,
        address _xCitadelLocker,
        address _policyDestination
    ) external initializer {
        __GlobalAccessControlManaged_init(_gac);
        
        supplySchedule = ISupplySchedule(_supplySchedule);
        citadelToken = _citadelToken;
        xCitadel = _xCitadel;
        xCitadelLocker = IxCitadelLocker(_xCitadelLocker);
        policyDestination = _policyDestination;

        emit SupplyScheduleSet(supplySchedule);
    }

    function mintAndDistribute(
        uint256 _fundingAmount,
        uint256 _stakingAmount,
        uint256 _lockingAmount
    ) external onlyRole(POLICY_OPERATIONS_ROLE) gacPausable {
        uint256 toMint = _fundingAmount.add(_stakingAmount).add(_lockingAmount);

        if (toMint == 0) {
            return;
        }
        
        ICitadelToken(citadelToken).mint(address(this), toMint);

        if (_fundingAmount != 0) {
            // Send funder amount to policy operations for distribution
            if (policyDestination != address(0)) {
                IERC20Upgradeable(citadelToken).safeTransfer(policyDestination, _fundingAmount);
            }
        }
        
        if (_stakingAmount != 0) {
            // Auto-compound staker amount into xCTDL
            IERC20Upgradeable(citadelToken).transfer(xCitadel, _stakingAmount);
        }

        if (_lockingAmount != 0 ) {
            IxCitadel(xCitadel).deposit(_lockingAmount);
            xCitadelLocker.notifyRewardAmount(xCitadel, _lockingAmount);
        }
    }

    /// @dev Highest governance level may swap out the supply schedule contract.
    function setSupplySchedule(ISupplySchedule _newSupplySchedule)
        external
        onlyRole(CONTRACT_GOVERNANCE_ROLE)
        gacPausable
    {
        supplySchedule = _newSupplySchedule;
        emit SupplyScheduleSet(_newSupplySchedule);
    }
}
