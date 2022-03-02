import pytest
from brownie import *

ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"

def ibbtc_whale(dev):
    whale = accounts.at("0xee1F07F88934C2811E3DcAbdf438d975C3d62cd3", force=True)
    ibbtc = Contract.from_explorer("0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F")
    ibbtc.transfer(dev, 1 * 10**18, {"from": whale})

def cvx_whale(dev):
    whale = accounts.at("0x790D08C25667f59F6cbA02452417fB081E3b9F1E", force=True)
    cvx = Contract.from_explorer("0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B")

    cvx.transfer(dev, 10_000 * 10**18, {"from": whale})

def token2(deployer):
    decimals = 18
    token_in = MockERC20.deploy("Test Token 2", "TEST2", decimals, {"from": deployer})

    # Mint 10 tokens to buyer
    amount = 10 * 10 ** decimals
    token_in.mint(amount, {"from": deployer})

    return token_in

def main():

    dev = accounts[0]

    # transfer ibbtc from whale to dev
    ibbtc_whale(dev)
    # transfer cvx from whale to dev
    cvx_whale(dev)

    #### actors ####
    deployer = dev
    policy_operator = dev
    policy_destination = dev

    governance = dev
    keeper = dev
    guardian = dev
    treasury = dev
    strategist = dev
    badgerTree = dev
    initialContractGovernance = dev

    gac = GlobalAccessControl.deploy({"from": deployer})
    gac.initialize(initialContractGovernance)
    POLICY_OPERATIONS_ROLE = web3.keccak(text="POLICY_OPERATIONS_ROLE")
    gac.grantRole(POLICY_OPERATIONS_ROLE, policy_operator.address, {"from": initialContractGovernance})
    print("[green]GAC was deployed at: [/green]", gac.address)

    citadel = CitadelToken.deploy({"from": deployer})
    citadel.initialize("Citadel", "CTDL", gac.address)
    print("[green]CTDL token was deployed at: [/green]", citadel.address)

    vesting_contract = Vesting.deploy({"from": deployer})
    vesting_contract.initialize(citadel.address)

    print("[green]Vesting contract was deployed at: [/green]", vesting_contract.address)

    xCTDL = xCitadel.deploy({"from": deployer})
    xCTDL.initialize(
        citadel.address,
        governance,
        keeper,
        guardian,
        treasury,
        strategist,
        badgerTree,
        vesting_contract.address,
        "xCitadel",
        "xCTDL",
        [0, 0, 0, 0],  # zero fees
    )

    print("[green]xCTDL vault was deployed at: [/green]", xCTDL.address)

    strat = MyStrategy.deploy({"from": deployer})
    strat.initialize(xCTDL.address, citadel.address)

    xCTDL.setStrategy(strat.address)

    print("[green]Strategy set to: [/green]", strat.address)

    vesting_contract.setVault(xCTDL.address, {"from": deployer})
    vesting_contract.transferOwnership(governance, {"from": deployer})

    locker = xCitadelLocker.deploy({"from": deployer})
    locker.initialize(xCTDL.address, "veCitadel", "veCTDL")

    print("[green]locker was deployed at: [/green]", locker.address)

    # add rewards to locker
    locker.addReward("0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B", dev, {"from": deployer}) # cvx
    locker.addReward("0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F", dev, {"from": deployer}) # ibbtc
    locker.addReward(xCTDL.address, dev, {"from": deployer}) # xCTDL

    locker.transferOwnership(governance, {"from": deployer})

    minter = CitadelMinter.deploy({"from": deployer})
    minter.initialize(
        gac.address,
        citadel.address,
        xCTDL.address,
        locker.address,
        policy_destination.address
    )
    
    CITADEL_MINTER_ROLE = web3.keccak(text="CITADEL_MINTER_ROLE")
    gac.grantRole(CITADEL_MINTER_ROLE, minter.address, {"from": initialContractGovernance})
    # granting citadel minting role to deployer to test easily
    gac.grantRole(CITADEL_MINTER_ROLE, deployer.address, {"from": deployer})

    token_sale = TokenSaleUpgradeable.deploy({"from": deployer})

    # CVX
    token_in = Contract.from_explorer("0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B")
    token_sale.initialize(
        citadel,  # tokenOut
        token_in,
        chain.time() + 10,  # saleStart
        86400,
        32, # price 32 usd / ctdl
        treasury,  # Sale recipient
        ADDRESS_ZERO,
        Wei("1000000 ether"),  # Sale cap in tokenIn
        {"from": deployer},
    )

    input("Press [Enter] to close.") 