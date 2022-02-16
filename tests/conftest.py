import pytest
from brownie import web3

POLICY_OPERATIONS_ROLE = web3.keccak(text="POLICY_OPERATIONS_ROLE")
CITADEL_MINTER_ROLE = web3.keccak(text="CITADEL_MINTER_ROLE")
ADDRESS_ZERO = "0x0000000000000000000000000000000000000000"
MAX_UINT256 = 2 ** 256 - 1


@pytest.fixture()
def minter(
    CitadelMinter, citadel_token, xCitadel, locker, gac, deployer, policy_destionation
):
    minter = CitadelMinter.deploy({"from": deployer})
    minter.initialize(
        gac.address,
        citadel_token.address,
        xCitadel.address,
        locker.address,
        policy_destionation.address,
    )

    gac.grantRole(CITADEL_MINTER_ROLE, minter.address)
    assert gac.hasRole(CITADEL_MINTER_ROLE, minter.address)

    yield minter


@pytest.fixture()
def gac(GlobalAccessControl, deployer, policy_operator):
    gac = GlobalAccessControl.deploy({"from": deployer})
    gac.initialize(deployer.address)

    gac.grantRole(POLICY_OPERATIONS_ROLE, policy_operator.address, {"from": deployer})
    assert gac.hasRole(POLICY_OPERATIONS_ROLE, policy_operator.address)

    yield gac


@pytest.fixture()
def citadel_token(CitadelToken, gac, deployer):
    citadel = CitadelToken.deploy({"from": deployer})
    citadel.initialize("Citadel", "CTDL", gac.address)

    yield citadel


@pytest.fixture()
def vesting(Vesting, citadel_token, deployer):
    vesting_contract = Vesting.deploy({"from": deployer})
    vesting_contract.initialize(citadel_token.address)

    yield vesting_contract


@pytest.fixture()
def xCitadel(xCitadel, MyStrategy, vesting, citadel_token, deployer):
    xCTDL = xCitadel.deploy({"from": deployer})
    xCTDL.initialize(
        citadel_token.address,
        deployer.address,
        deployer.address,
        deployer.address,
        deployer.address,
        deployer.address,
        deployer.address,
        vesting.address,
        "xCitadel",
        "xCTDL",
        [0, 0, 0, 0],  # zero fees
    )

    strat = MyStrategy.deploy({"from": deployer})
    strat.initialize(xCTDL.address, citadel_token.address)

    xCTDL.setStrategy(strat.address)

    vesting.setVault(xCTDL.address, {"from": deployer})

    yield xCTDL


@pytest.fixture()
def locker(xCitadelLocker, xCitadel, deployer):
    Locker = xCitadelLocker.deploy({"from": deployer})
    Locker.initialize(xCitadel.address, "veCitadel", "veCTDL")

    yield Locker


### ACTORS ###


@pytest.fixture()
def deployer(accounts):
    yield accounts[0]


@pytest.fixture()
def policy_operator(accounts):
    yield accounts[1]


@pytest.fixture()
def policy_destionation(accounts):
    yield accounts[2]


@pytest.fixture()
def rando(accounts):
    yield accounts[3]


@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass
