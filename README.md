# Zentra

A decentralized synthetic asset protocol that gives users in emerging markets borderless access to global financial assets — tracked, minted, and traded entirely on-chain.

---

## Overview

Zentra is a modular system of Clarity smart contracts enabling anyone to mint, hold, and trade synthetic versions of real-world assets such as stocks, commodities, and indexes — without needing access to the underlying asset or traditional finance.

It consists of the following core contracts:

1. **Collateral Vault Contract** – Manages collateral deposits for minting synthetic assets.
2. **Synth Token Contract** – Issues and tracks synthetic assets (e.g. sUSD, sAAPL, sGOLD).
3. **Minting Engine Contract** – Handles minting and burning based on collateralization ratios.
4. **Price Oracle Contract** – Pulls secure price feeds from real-world markets.
5. **Stability Pool Contract** – Ensures peg stability by rewarding users who stake to back undercollateralized positions.
6. **Liquidation Engine Contract** – Automatically liquidates unhealthy positions and redistributes collateral.
7. **Governance DAO Contract** – Community governance over parameters like collateral ratios, fees, and asset whitelisting.
8. **Fee Router Contract** – Routes and distributes protocol fees to stakers, LPs, and the treasury.
9. **Synth AMM Contract** – Facilitates low-slippage trading between synthetic assets.
10. **Bridge Adapter Contract** – Enables cross-chain minting and redemption for supported L2s.

---

## Features

- **Decentralized access to synthetic stocks, indexes, and commodities**  
- **Overcollateralized minting engine** backed by stablecoins or BTC  
- **Real-time asset pricing** via decentralized oracles  
- **Liquidation safety nets** through a stability pool  
- **Community governance** over protocol parameters  
- **Yield opportunities** via staking, stability pool, and LPs  
- **Bridging and multi-chain support**  
- **Permissionless minting and trading**

---

## Smart Contracts

### Collateral Vault Contract
- Accepts STX or stablecoins as collateral
- Manages user vaults and deposit balances
- Ensures asset-backed minting eligibility

### Synth Token Contract
- Deploys and manages each synthetic asset token (e.g. sAAPL, sUSD)
- Ensures pegging logic via oracle price updates
- Burn/mint on-demand based on protocol rules

### Minting Engine Contract
- Core engine to issue synthetic assets
- Validates collateral ratios
- Facilitates mint and burn operations

### Price Oracle Contract
- Integrates with Chainlink or trusted off-chain relays
- Verifies live price feeds for all listed assets
- Time-weighted average price (TWAP) calculations

### Stability Pool Contract
- Users stake native governance tokens (e.g. $ZTRA)
- Covers bad debt from undercollateralized positions
- Rewards stakers with fees and liquidation bonuses

### Liquidation Engine Contract
- Monitors vault health
- Executes automated liquidations if collateral falls below threshold
- Redistributes seized collateral to stakers and treasury

### Governance DAO Contract
- Community-driven voting on new synthetic assets
- Adjust collateral ratios, fees, and oracle sources
- Token-weighted proposal system

### Fee Router Contract
- Collects minting, burning, and swap fees
- Splits fees across treasury, stakers, and LPs
- Transparent and programmable routing

### Synth AMM Contract
- Peer-to-peer trading between synthetic assets
- Low-slippage routing and pooled liquidity
- Peg protection mechanisms

### Bridge Adapter Contract
- Supports cross-chain minting/redemption
- Enables asset portability across supported chains
- Integrates with trusted bridges (e.g. BTC L2, Ethereum L2)

---

## Installation

1. Install [Clarinet CLI](https://docs.hiro.so/clarinet/getting-started)
2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/zentra.git
   ```
3. Run tests:
    ```bash
    npm test
    ```
4. Deploy contracts:
    ```bash
    clarinet deploy
    ```

    ---

## Usage

Each contract is modular but designed to integrate tightly with others in the Zentra protocol. For individual contract functions, see the /contracts directory and corresponding .clar files.

Use the Oracle, Collateral Vault, and Minting Engine in tandem to simulate end-to-end synthetic asset issuance and trading.

---

## License

MIT License