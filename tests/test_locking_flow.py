import brownie
from brownie import *

import pytest

from conftest import CITADEL_MINTER_ROLE, MAX_UINT256

from helpers.utils import (
    approx,
)

amount = 1e18

def test_locking_flow(citadel_token, deployer, rando, gac, xCitadel, locker):
    
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

    # lock xCitadel 
    
    xCitadel.approve(locker, MAX_UINT256, {"from": rando})
    locker.lock(rando.address, xCitadel.balanceOf(rando), 0, {"from": rando})
    assert locker.lockedBalanceOf(rando.address) == amount

    ## mint some rewards for xCitadelLocker - 1 xCTDL / day
    locker.addReward(xCitadel.address, deployer, {"from": deployer})

    citadel_token.mint(deployer, 10*amount, {"from": deployer})
    citadel_token.approve(xCitadel, MAX_UINT256, {"from": deployer})
    xCitadel.deposit(10*amount, {"from": deployer})
    xCitadel.approve(locker, MAX_UINT256, {"from": deployer})
    locker.notifyRewardAmount(xCitadel.address, amount, {"from": deployer})
    assert locker.getRewardForDuration(xCitadel.address) > 0
    
    # sleep for 1 day
    chain.sleep(86400)
    chain.mine()

    claimableRewards = locker.claimableRewards(rando)[0][1]
    assert claimableRewards > 0

    # get xCitadel rewards
    prev_xCitadel_balance = xCitadel.balanceOf(rando)
    locker.getReward(rando, False)
    post_xCitadel_balance = xCitadel.balanceOf(rando)

    assert post_xCitadel_balance - prev_xCitadel_balance == claimableRewards

    # sleep for 21 weeks
    chain.sleep(12700800)
    chain.mine()

    prev_xCitadel_balance = xCitadel.balanceOf(rando)
    locker.processExpiredLocks(False, {"from": rando})
    post_xCitadel_balance = xCitadel.balanceOf(rando)

    assert post_xCitadel_balance - prev_xCitadel_balance > 0
