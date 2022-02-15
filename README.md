# Citadel (CTDL) Token:
Upgradeable ERC20 token with admin minting rights

# xCitadel Vault:
fork of badger vaults 1.5 with no strategy which allows users to deposit CTDL token and receive xCTDL token. 

Vault has a 21 day exit vesting period.

## Vesting contract:
upon withdraw from xCitadel vault CTDL tokens are sent to vesting contract wherein they are vested linearly for 21 days

# xCitadelLocker:
allows locking of xCTDL token for 21 weeks based upon the convex locker model.

<strong> modifications made to convex locker: </strong>
- locker made upgradeable
- staking contract is disabled so all the xCTDL token would remain in the locker
- addRewards modified to allow distribution of staking token too
- `kickRewardPerEpoch` removed from function `_processExpiredLocks` to disable giving of kick rewards