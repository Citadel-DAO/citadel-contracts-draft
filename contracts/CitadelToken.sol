// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/proxy/Initializable.sol";

import "./lib/GlobalAccessControlManaged.sol";

contract CitadelToken is GlobalAccessControlManaged, ERC20Upgradeable {
    bytes32 public constant CITADEL_MINTER_ROLE =
        keccak256("CITADEL_MINTER_ROLE");

    /**
     * @dev intialize.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _gac
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __GlobalAccessControlManaged_init(_gac);
    }

    /**
     * @dev Mints new tokens.
     * @param dest The address to mint the new tokens to.
     * @param amount The quantity of tokens to mint.
     */
    function mint(address dest, uint256 amount)
        external
        onlyRole(CITADEL_MINTER_ROLE)
        gacPausable
    {
        _mint(dest, amount);
    }
}
