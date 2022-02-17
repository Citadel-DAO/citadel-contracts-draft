import brownie
from brownie import *

import pytest

from conftest import CITADEL_MINTER_ROLE, MAX_UINT256

from helpers.utils import (
    approx,
)

amount = 1e18


def test_minting_flow(
    minter,
    citadel_token,
    xCitadel,
    locker,
    deployer,
    policy_operator,
    policy_destionation,
):
    locker.addReward(xCitadel.address, minter, {"from": deployer})

    minter.mintAndDistribute(amount, amount, amount, {"from": policy_operator})

    assert citadel_token.balanceOf(xCitadel) == 3 * amount
    # policy_destionation balance of xCitadel should be equal to amount
    # as currently the vault has no deposits 
    assert xCitadel.balanceOf(policy_destionation) == amount
    # as ppfs = 0.5 ether therefore xCitadel balance of locker will be 0.5 xCitadel
    assert xCitadel.balanceOf(locker) == 0.5 * amount
