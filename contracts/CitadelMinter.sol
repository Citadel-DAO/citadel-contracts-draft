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
import "../interfaces/citadel/IxCitadel.sol";
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

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE = keccak256("CONTRACT_GOVERNANCE_ROLE");
    bytes32 public constant POLICY_OPERATIONS_ROLE = keccak256("POLICY_OPERATIONS_ROLE");

    ISupplySchedule public supplySchedule;
    IERC20Upgradeable public citadelToken;
    IxCitadel public xCitadel;

    uint constant MAX_BPS = 10000;

    event SupplyScheduleSet(ISupplySchedule supplySchedule);

    function initialize(address _gac, ISupplySchedule _supplySchedule, IERC20Upgradeable _citadelToken, IxCitadel _xCitadel) external initializer {
        __GlobalAccessControlManaged_init(_gac);
        supplySchedule = _supplySchedule;
        citadelToken = _citadelToken;
        xCitadel = _xCitadel;

        emit SupplyScheduleSet(_supplySchedule);
    }

    function mintAndDistribute(uint marketcap, uint treasury, uint supplyStakedBps, uint supplyLockedBps) external onlyRole(POLICY_OPERATIONS_ROLE) gacPausable {
        // The minted tokens allocated to funding will be sent to the policy operations manager
        address policyDestination = gac.getRoleMember(POLICY_OPERATIONS_ROLE, 0);

        uint toMint = supplySchedule.getMintable();
        // citadelToken.mint(toMint);

        uint toStakersBps = MAX_BPS;
        uint toLockersBps = MAX_BPS;
        uint toFundingBps = MAX_BPS;

        uint toFundingAmount = toMint.mul(toFundingBps).div(MAX_BPS);
        uint toLockersAmount = toMint.mul(toLockersBps).div(MAX_BPS);

        // Round down to stakers
        uint toStakersAmount = toMint.sub(toFundingAmount).sub(toLockersAmount);

        // Send funder amount to policy operations for distribution
        // citadelToken.transfer(toFundingAmount, policyDestination);
    
        // Auto-compound staker amount into xCTDL
        // citadelToken.transfer(toStakersAmount, xCitadel);

        // Modify emission schedule for Lockers
        // citadelToken.notifyRewardAmount(toFundingAmount, policyDestination);
    }

    /// @dev Highest governance level may swap out the supply schedule contract.
    function setSupplySchedule(ISupplySchedule _newSupplySchedule) external onlyRole(CONTRACT_GOVERNANCE_ROLE) gacPausable {
        supplySchedule = _newSupplySchedule;
        emit SupplyScheduleSet(_newSupplySchedule);
    }

}