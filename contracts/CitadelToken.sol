// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CitadelToken is ERC20, Ownable {

    /**
     * @dev Constructor.
     */
    constructor() ERC20("Citadel", "CTDL") public {
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