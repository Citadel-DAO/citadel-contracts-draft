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

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");
    bytes32 public constant POLICY_OPERATIONS_ROLE =
        keccak256("POLICY_OPERATIONS_ROLE");

    ISupplySchedule public supplySchedule;
    IERC20Upgradeable public citadelToken;
    IxCitadel public xCitadel;

    uint256 constant MAX_BPS = 10000;

    event SupplyScheduleSet(ISupplySchedule supplySchedule);

    function initialize(
        address _gac,
        address _supplySchedule,
        address _citadelToken,
        address _xCitadel
    ) external initializer {
        __GlobalAccessControlManaged_init(_gac);
        supplySchedule = ISupplySchedule(_supplySchedule);
        citadelToken = IERC20Upgradeable(_citadelToken);
        xCitadel = IxCitadel(_xCitadel);

        emit SupplyScheduleSet(supplySchedule);
    }

    function mintAndDistribute(
        uint256 marketcap,
        uint256 treasury,
        uint256 supplyStakedBps,
        uint256 supplyLockedBps
    ) external onlyRole(POLICY_OPERATIONS_ROLE) gacPausable {
        // The minted tokens allocated to funding will be sent to the policy operations manager
        address policyDestination = gac.getRoleMember(
            POLICY_OPERATIONS_ROLE,
            0
        );

        uint256 toMint = supplySchedule.getMintable();

        // citadelToken.mint(address(this), toMint);
        
        uint256 toStakersBps = MAX_BPS;
        uint256 toLockersBps = MAX_BPS;
        uint256 toFundingBps = MAX_BPS;

        uint256 toFundingAmount = toMint.mul(toFundingBps).div(MAX_BPS);
        uint256 toLockersAmount = toMint.mul(toLockersBps).div(MAX_BPS);

        // Round down to stakers
        uint256 toStakersAmount = toMint.sub(toFundingAmount).sub(
            toLockersAmount
        );

        // Send funder amount to policy operations for distribution
        // citadelToken.transfer(toFundingAmount, policyDestination);

        // Auto-compound staker amount into xCTDL
        // citadelToken.transfer(toStakersAmount, xCitadel);

        // Modify emission schedule for Lockers
        // citadelToken.notifyRewardAmount(toFundingAmount, policyDestination);

        // lets say -  
        // reward rate = prev_reward
        // finish time t > block.timestamp
        // 5 / 1 day = reward rate
        // after half a day we (finish_time - block.timestamp)
        // 2.5 = 0.5 + 1.5
        // so now whenever we update the reward rate it changes from the current timestamp
        // get the existing reward data
        // RewardData data = xCitadelLocker.rewardData(address)

        // if (data.finish_time < block.timestamp) {
        //     // whatever rate we want to set * ( rewardDuration )
        // } else {
        //     // change reward rate 
        //     // remainingTime = data.finish_time - block.timestamp
        //     // leftRewards = data.rewardRate * remainingTime
        //     // now whatever reward rate we want 
        //     // (amount to transfer + leftRewards) / rewards Duration
        //     // the reward rate changes immediately for the next reward duration
        // }
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
