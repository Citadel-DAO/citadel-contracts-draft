// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin-contracts-upgradeable/proxy/Initializable.sol";

contract CitadelToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    /**
     * @dev intialize.
     */
    function initialize(string memory _name, string memory _symbol)
        public
        initializer
    {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
    }

    /**
     * @dev Mints new tokens.
     * @param dest The address to mint the new tokens to.
     * @param amount The quantity of tokens to mint.
     */
    function mint(address dest, uint256 amount) external onlyOwner {
        _mint(dest, amount);
    }
}
