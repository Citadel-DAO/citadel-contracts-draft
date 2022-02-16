import brownie
from brownie import *

import pytest

from conftest import CITADEL_MINTER_ROLE, MAX_UINT256

from helpers.utils import (
    approx,
)

amount = 1e18

def test_minting_flow(minter, citadel_token, xCitadel, locker, deployer, policy_operator, policy_destionation):
    locker.addReward(xCitadel.address, minter, {"from": deployer})

    minter.mintAndDistribute(amount, amount, amount, {"from": policy_operator})
    
    assert citadel_token.balanceOf(xCitadel) == 2 * amount
    assert citadel_token.balanceOf(policy_destionation) == amount
    assert xCitadel.balanceOf(locker) == amount
