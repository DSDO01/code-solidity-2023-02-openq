# OpenQ contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Resources

- See "About OpenQ" below
- To run tests, run `yarn` followed by `yarn test`

# On-chain context

```
DEPLOYMENT: polygon mainnet
ERC20: any
ERC721: any
ERC777: any
FEE-ON-TRANSFER: any
REBASING TOKENS: any
ADMIN: trusted for upgrades, restricted elsewhere
EXTERNAL-ADMINS: oracle
```

In case of restricted, by default Sherlock does not consider direct protocol rug pulls as a valid issue unless the protocol clearly describes in detail the conditions for these restrictions.

For contracts, owners, admins clearly distinguish the ones controlled by protocol vs user controlled. This helps watsons distinguish the risk factor.

## OpenQV1.sol

* `OpenQV1.sol` is owned by the protocol.
* 
* `OpenQV1.sol` is UUPS Upgradeable and therefore should only be initialized ONCE and thereafter always called via `OpenQProxy.sol`.

* `owner` in `OpenQV1.sol` should be the SOLE CALLER of these 5 methods:

- `setBountyFactory`
- `setClaimManager`
- `setDepositManager`
- `_authorizeUpgrade`
- `transferOracle`

* `oracle` in `OpenQV1` should be the SOLE CALLER of this 1 method:

- `associateExternalIdToAddress`

## DepositManagerV1.sol

* `DepositManagerV1.sol` is owned by the protocol.

* `DepositManagerV1.sol` is UUPS Upgradeable and therefore should only be initialized ONCE and thereafter always called via a `OpenQProxy.sol`.

* `owner` in `DepositManagerV1.sol` should be the SOLE CALLER of these 2 methods:

- `setTokenWhitelist`
- `_authorizeUpgrade`

## ClaimManagerV1.sol

* `ClaimManagerV1.sol` is owned by the protocol. 

* `ClaimManagerV1.sol` is UUPS Upgradeable and therefore should only be initialized ONCE and thereafter always called via `OpenQProxy.sol`.

* `owner` in `ClaimManagerV1.sol` should be the SOLE CALLER of these 2 methods:

- `_authorizeUpgrade`
- `transferOracle`
- `setOpenQ`

* `oracle` in `ClaimManagerV1.sol` should be the SOLE CALLER of this 1 method:

- `claimBounty`

## BountyFactory.sol

* `BountyFactory.sol` is owned by the protocol.

* `BountyFactory.mintBounty` should only be called by the OpenQ proxy address.

* `BountyFactory.sol` is not upgradeable. If an update is needed, we would simply re-deploy a new BountyFactory and set it on OpenQ with the only-owner `setBountyFactory` method.

## BountyV1 of all types (AtomicBountyV1, OngoingBountyV1, TieredFixedBountyV1, TieredPercentageBountyV1)

* `BountyV1.sol` is owned by the minter/issuer of the bounty, as held in `bounty.issuer`.

* The issuer/minter of the bounty should be the sole user able to call the follwoing methods on OpenQ:

- `setTierWinner`
- `setFundingGoal`
- `setKycRequired`
- `setInvoiceRequired`
- `setSupportingDocumentsRequired`
- `setInvoiceComplete`
- `setSupportingDocumentsComplete`
- `setPayout`
- `setPayoutSchedule`
- `setPayoutScheduleFixed`
- `closeOngoing`

* `BountyV1.sol` is, however, a Beacon Proxy, and each Beacon Proxy held on BountyFactory is owned by the protocol.

* The BeaconProxy should only be able to be upgraded by the beacon proxy owner.

## OpenQTokenWhitelist.sol

* `owner` of `OpenQTokenWhitelist.sol` should be the SOLE CALLER of the following 3 methods:

- addToken
- removeToken
- setTokenAddressLimit

* Because certain bounty types accept any ERC20, and payouts occur in for-loops of `safeTransferFrom`'s in `OpenQV1.sol`, OpenQTokenWhitelist is meant to limit the amount of token addresses able to deposit on a bounty in order to avoid OUT_OF_GAS attacks.

# Audit scope

Includes:

- All contracts in `/contracts`, **EXCLUDING** the `Mocks` directory

Excludes:

- Any off-chain services, like our oracles which are all running in Node.js on Open Zeppelin Defender Autotask.

# About OpenQ

# OpenQ Audit 👨‍💻🥷👩‍💻

Hello! Thank you for hacking OpenQ.

Give it your all, pull no punches, and try your best to mess us up.

Here's everything you need to get started. Godspeed!

## About Us

OpenQ is a Github-integrated, crypto-native and all-around-automated marketplace for software engineers.

We specialize in providing tax-compliant, on-chain hackathon prize distributions.

## How People Use Us

You can read all about how OpenQ works from the user's perspective by reading our docs.

https://docs.openq.dev

## Technical Background

Blockchain: `Polygon Mainnet`

Language: `solidity 0.8.17`

## Scope

Includes:

- All contracts in `/contracts`, **EXCLUDING** the `Mocks` directory

Excludes:

- Any off-chain services, like our oracles

## Trusted Services

- Assume OpenQ Oracles are trusted
- Assume KYC DAO is secure, and only has NFTs for addresses which have undergone their KYC process

## Architecture Overview

### Upgradeability

#### UUPSUPgradeable

`OpenQV1.sol`, `ClaimManagerV1.sol` and `DepositManagerV1.sol` are all [UUPSUpgradeable](https://docs.openzeppelin.com/contracts/4.x/api/proxy). 

The implementation lies behind a proxy.

#### Beacon Proxy

All bounty types, `AtomicBountyV1.sol`, `OngoingBountyV1.sol`, `TieredPercentageBountyV1.sol`, `TieredFixedBountyV1.sol` are also upgradeable.

Because we have MANY deployed at any one time and want to be able to update them without calling `upgradeTo()` on each contract, we use the [Beacon Proxy pattern](https://docs.openzeppelin.com/contracts/3.x/api/proxy#beacon).

Each bounty contract lies behind a proxy. That proxy gets it's target for `delegatecall`'s from the appropriate beacon set during minting on `BountyFactory.mintBounty`.

#### Bounty Factory

Bounty Factory holds Beacons for all 4 bounty types as storage variables on it.

When it mints a bounty, it passes to it the appropriate beacon.

Since each bounty is a [BeaconProxy](https://docs.openzeppelin.com/contracts/3.x/api/proxy#BeaconProxy).

## Developer Perspective on All OpenQ Flows: Minting, Funding and Claiming

## Contract Types

OpenQ supports FOUR types of contracts.

Each one differs in terms of:

- Number of claimants
- Fixed payout (e.g. 100 USDC), percentage payout (e.g. 1st place gets 50% of all escrowed funds), or whatever the full balances are on the bounty (funded with anything, full balance paid to claimant)

The names for those four types are:

- `ATOMIC`: These are fixed-price, single contributor contracts
- `ONGOING`: These are fixed-price, multiple contributors can claim, all receiving the same amount
- `TIERED_PERCENTAGE`: A crowdfundable, percentage based payout for each tier (1st, 2nd, 3rd)
- `TIERED_FIXED`: Competitions with fixed price payouts for each tier (1st, 2nd, 3rd)

### Minting a Bounty

Minting a bounty begins at `OpenQ.mintBounty(bountyId, organizationId, initializationData)`.

Anyone can call this method to mint a bounty.

`OpenQV1.sol` then calls `bountyFactory.mintBounty(...)`.

The BountyFactory deploys a new `BeaconProxy`, pointing to the `beacon` address which will point each bounty to the proper implementation.

All the fun happens in the `InitOperation`. This is an ABI encoding of everything needed to initialize any of the four types of contracts.

The BountyV1.sol `initialization` method passes this `InitOperation` to `_initByType`, which then reads the type of bounty being minted, initializing the storage variables as needed.

### Funding a Bounty

All funding of bounties MUST go through the `DepositManagerV1.fundBountyToken()` or `DepositManagerV1.fundNft()` methods.

This is because the DepositManager address is where events are emitted, which we use in the [OpenQ subgraph](https://thegraph.com/hosted-service/subgraph/openqdev/openq).

All bounties use the core function `receiveFunds` inherited from `BountyCore.sol` to actually transfer the approved funds and NFTs.

All deposits are **TIMELOCKED** and become refundable after the deposit's `expiration` perioid by calling `DepositManager.refundDeposit`.

### Claiming a Bounty

All bounty claims are managed by `ClaimManagerV1.sol`.

There are two methods that allow for claims: `claimBounty`, and `permissionedClaimTieredBounty`.

#### `claimBounty`

`claimBounty` is only callable by the OpenQ oracle per the `Oraclize.onlyOracle` modifier.

The OpenQ oracle is an [Open Zeppelin Defender Autotask](https://docs.openzeppelin.com/defender/autotasks) attached to a signer using [Open Zeppelin Defender Relay](https://docs.openzeppelin.com/defender/relay).

All bounty types can be claimed this way. Depending on the use case, users like hackathon organizers might prefer a "pull" rather than "push" method of payment.

That is where `permissionedClaimTieredBounty` comes in for tiered bounties.

#### `permissionedClaimTieredBounty`

`permissionedClaimTieredBounty` allows a user who has associated their external user id (usually an OpenQ user id) to an on-chain address to claim a tier.

This on-chain/off-chain association is set in `OpenQV1.associateExternalIdToAddress` and protected by `onlyOracle`. We have another Open Zeppelin Defender Autotask that authenticates the user and calls this method with the desired associated address if authentication is successful.

With this two-way association between external user id and address, we can fetch the external user id from `msg.sender` and determine if `TieredBounty.tierWinner(userId)` is indeed the address who has been designate by the bounty issuer as the winner.

### Potential Exploits (free alpha!)

- Messing with `OpenQV1.associateExternalIdToAddress` to claim another user's tier.

#### Directly sending tokens to the bounty address

While not explicitly refused (which we can't, since ERC20 doesn't have any kind of callback mechanism for an address to know when it has received ERC20), bounty's should only be funded via DepositManager.

No guarantees can be made for payouts of funds directly sent to a bounty contract address.