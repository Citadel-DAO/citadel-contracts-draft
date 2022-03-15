// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

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
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");
    bytes32 public constant POLICY_OPERATIONS_ROLE =
        keccak256("POLICY_OPERATIONS_ROLE");

    address public citadelToken;
    address public xCitadel;
    // The minted tokens allocated to funding will be sent to the policy operations manager
    address public policyDestination;
    IxCitadelLocker public xCitadelLocker;

    uint256 constant MAX_BPS = 10000;

    EnumerableSetUpgradeable.AddressSet internal fundingPools;
    mapping (address => uint) fundingPoolWeights;
    uint totalFundingPoolWeight;

    event FundingPoolWeightSet(uint weight, bool increased, uint diff, uint totalFundingPoolWeight);

    function initialize(
        address _gac,
        address _citadelToken,
        address _xCitadel,
        address _xCitadelLocker,
        address _policyDestination
    ) external initializer {
        require(_gac != address(0), "address 0 invalid");
        require(_citadelToken != address(0), "address 0 invalid");
        require(_xCitadel != address(0), "address 0 invalid");
        require(_xCitadelLocker != address(0), "address 0 invalid");
        require(_policyDestination != address(0), "address 0 invalid");

        __GlobalAccessControlManaged_init(_gac);

        citadelToken = _citadelToken;
        xCitadel = _xCitadel;
        xCitadelLocker = IxCitadelLocker(_xCitadelLocker);
        policyDestination = _policyDestination;

        // Approve xCitadel vault for use of citadel tokens
        IERC20Upgradeable(citadelToken).approve(xCitadel, 2**256 - 1);
        // Approve xCitadel for locker to use
        IERC20Upgradeable(xCitadel).approve(_xCitadelLocker, 2**256 - 1);
    }

    // @dev Set the funding weight for a given address. 
    // @dev Verification on the address is performed via a proper return value on a citadelContractType() call. 
    // @dev setting funding pool weight to 0 for an existing pool will delete it from the list
    function setFundingPoolWeight(address _pool, uint _weight) external onlyRole(POLICY_OPERATIONS_ROLE) gacPausable {
        bool poolExists = fundingPools.contains(_pool);
        // Remove existing pool on 0 weight
        if (_weight == 0 && poolExists) {
            _setFundingPoolWeight(_pool, 0);
            _removeFundingPool(_pool);
        } else {
            require(_weight <= 10000, "exceed max funding pool weight");
            if (!poolExists) {
                _addFundingPool(_pool);
            }
            _setFundingPoolWeight(_pool, _weight);
        }
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

        if (_stakingAmount != 0) {
            // Auto-compound staker amount into xCTDL
            IERC20Upgradeable(citadelToken).transfer(xCitadel, _stakingAmount);
        }   

        // Old Method: Deposit in xCTDL and send to policy manager multisig
        // if (_fundingAmount != 0) {
        //     uint256 _before = IERC20Upgradeable(xCitadel).balanceOf(
        //         address(this)
        //     );
        //     IxCitadel(xCitadel).deposit(_fundingAmount);
        //     uint256 _after = IERC20Upgradeable(xCitadel).balanceOf(
        //         address(this)
        //     );

        //     // Send funder amount to policy operations for distribution
        //     IERC20Upgradeable(xCitadel).safeTransfer(
        //         policyDestination,
        //         _after.sub(_before)
        //     );
        // }

        if (_fundingAmount != 0) {
            _transferToFundingPools(_fundingAmount);
        }
            
        if (_lockingAmount != 0) {
            uint256 beforeAmount = IERC20Upgradeable(xCitadel).balanceOf(
                address(this)
            );
            IxCitadel(xCitadel).deposit(_lockingAmount);
            uint256 afterAmount = IERC20Upgradeable(xCitadel).balanceOf(
                address(this)
            );

            xCitadelLocker.notifyRewardAmount(
                xCitadel,
                afterAmount.sub(beforeAmount)
            );
        }
    }

    // ===== Internal Functions =====

    // === Funding Pool Management ===
    function _transferToFundingPools(uint _citadelAmount) internal {
        require(fundingPools.length() > 0, "no funding pools");
        for (uint i = 0; i < fundingPools.length(); i++) {
            address pool = fundingPools.at(i);
            uint weight = fundingPoolWeights[pool];

            uint amonut = _citadelAmount * weight / totalFundingPoolWeight;

            IERC20Upgradeable(citadelToken).safeTransfer(
                pool,
                amonut
            );
        }
    }

    function _setFundingPoolWeight(address _pool, uint _weight) internal {
        uint existingWeight = fundingPoolWeights[_pool];

        // Decreasing Weight
        if (existingWeight > _weight) {
            uint diff = existingWeight - _weight;

            fundingPoolWeights[_pool] = _weight;
            totalFundingPoolWeight -= diff;
            emit FundingPoolWeightSet(_weight, false, diff, totalFundingPoolWeight);
        }

        // Increasing Weight
        else if (existingWeight < _weight) {
            uint diff = _weight - existingWeight;
            
            fundingPoolWeights[_pool] = _weight;
            totalFundingPoolWeight += diff;
            emit FundingPoolWeightSet(_weight, true, diff, totalFundingPoolWeight);
        }

        // If weight values are the same, no action is needed
    }

    function _removeFundingPool(address _pool) internal {
        require(fundingPools.remove(_pool), "funding pool does not exist for removal");
    }

    function _addFundingPool(address _pool) internal {
        require(fundingPools.add(_pool), "funding pool already exists");
    }


}
