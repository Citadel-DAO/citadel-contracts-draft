import brownie
from brownie import *

import pytest

from conftest import CITADEL_MINTER_ROLE, MAX_UINT256

from helpers.utils import (
    approx,
)

amount = 1e18
VESTING_TIME = 864000  # 10 days


def test_stake_withdraw_flow(citadel_token, gac, xCitadel, vesting, deployer, rando):

    # gives deployer citadel minting rights
    gac.grantRole(CITADEL_MINTER_ROLE, deployer.address)
    assert gac.hasRole(CITADEL_MINTER_ROLE, deployer.address)

    ## mint CTDL tokens to rando

    citadel_token.mint(rando, amount, {"from": deployer})
    assert citadel_token.balanceOf(rando) == amount

    ## stake CTDL to get xCTDL tokens

    citadel_token.approve(xCitadel, MAX_UINT256, {"from": rando})
    xCitadel.deposit(amount, {"from": rando})
    # user receives equivalent amount of xCTDL as ppfs = 1
    assert xCitadel.balanceOf(rando) == amount
    # xCitadel vault has 1 CTDL token
    assert citadel_token.balanceOf(xCitadel.address) == amount

    ## withdraw token and test vesting

    xCitadel.withdrawAll({"from": rando})
    # vesting contract should receive the withdrawn CTDL token
    assert citadel_token.balanceOf(vesting.address) == amount
    assert vesting.claimableBalance(rando.address) == 0

    chain.sleep(VESTING_TIME)
    chain.mine()

    (vestingStart, _, _, _) = vesting.vesting(rando)

    claimableBalance = (
        amount * (chain.time() - vestingStart)
    ) / vesting.VESTING_DURATION()

    vesting.claim(rando, MAX_UINT256, {"from": rando})
    # after half of time passes when claiming user should be able to claim only half amount
    assert citadel_token.balanceOf(rando) >= claimableBalance

    chain.sleep(VESTING_TIME * 3)  # sleep for more than 21 days
    chain.mine()

    vesting.claim(rando, MAX_UINT256, {"from": rando})
    # after half of time passes when claiming user should be able to claim only half amount
    assert citadel_token.balanceOf(rando) == amount
