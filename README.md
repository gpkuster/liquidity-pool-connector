# 🔌 Liquidity Pool Connector

This project is designed to facilitate token swaps and manage liquidity in a Uniswap V2-compatible decentralized exchange. It is optimized for usage on networks like Arbitrum (migration to Uniswap V3 in progress 📈).

## 📜 Overview

This project provides:

- A smart contract that:
  - Swaps tokens through a defined path
  - Adds liquidity to a USDT/DAI pool
  - Removes liquidity from the pool
- A set of tests using Foundry and a forked mainnet environment

## 🛠️ Technologies Used

- Solidity ^0.8.24
- Foundry (testing framework)
- OpenZeppelin Contracts (ERC20 utilities)
- Uniswap V2-compatible router and factory

## 🧠 How It Works

**Token Swapping**  
Allows users to swap one token for another using a specified path through supported liquidity pools.

**Add Liquidity**  
Splits the user's input tokens, performs a swap to balance the pair, and adds both tokens to the liquidity pool.

**Remove Liquidity**  
Burns the user's LP tokens to withdraw the underlying assets from the pool.

## 🧪 Testing

The test suite is built on Foundry and uses a forked Arbitrum mainnet to simulate realistic conditions. The coverage is 100%
```
╭-----------------+-----------------+-----------------+---------------+---------------╮
| File            | % Lines         | % Statements    | % Branches    | % Funcs       |
+=====================================================================================+
| src/SwapApp.sol | 100.00% (26/26) | 100.00% (27/27) | 100.00% (0/0) | 100.00% (4/4) |
|-----------------+-----------------+-----------------+---------------+---------------|
| Total           | 100.00% (26/26) | 100.00% (27/27) | 100.00% (0/0) | 100.00% (4/4) |
╰-----------------+-----------------+-----------------+---------------+---------------╯
```

### Prerequisites

- Foundry installed
- RPC endpoint for Arbitrum mainnet (e.g., via Chainlist)

### Run Tests
Please note that the test suite is designed for froked tests, so running tests locally won't work. Use the following commands:

- To execute tests with full logs
```
forge test -vvvv --fork-url https://arb1.arbitrum.io/rpc
```
- To check test coverage
```
forge coverage --fork-url https://arb1.arbitrum.io/rpc
```

### Github Workflow
⚠️ Please note if forking: There's a secret in this project's config called `FORK_URL` that you need to set in order to make the workflow pass at the [test step](https://github.com/gpkuster/liquidity-pool-connector/blob/31f3b29093b9b2510ab45d7812a9d170601d90b7/.github/workflows/test.yml#L37)

## 🔐 Security Notes

- This contract assumes the use of trusted tokens and router contracts.
- There are no access controls or role restrictions—intended for demo or educational purposes.
- Use in production should involve additional safety mechanisms.

## 📂 Project Structure

- `src/` contains the smart contract (`SwapApp.sol`)
- `test/` contains the test file (`SwapAppTest.sol`)
- `lib/` includes OpenZeppelin dependencies
- `interfaces/` defines the router and factory interfaces

## 🚀 Future Improvements

Here are some possible improvements and extensions for the Liquidity Pool Connector:

### 🔄 Upgrade to Uniswap V4 (migration to v3 in progress since v4 is still under development)

- **Migration to Uniswap V4 architecture** to benefit from:
  - Singleton contract design (reduced gas costs)
  - Hooks for custom logic during swaps and liquidity provisioning
  - Native support for on-chain limit orders and dynamic fees
- Adjust function signatures and contract interactions to match the new V4 router and pool structure

### 🛡️ Add Access Control (RBAC)

- Restrict access to sensitive functions (e.g., using `Ownable` or `AccessControl`)
- Enable role-based permissions for liquidity managers, admins, or automated bots

### 📊 Integrate Real-Time Price Feeds

- Use Chainlink oracles to validate token prices before performing swaps
- Prevent front-running or slippage attacks by validating price tolerances off-chain

### ⚙️ Slippage Control & Configurability

- Let users set slippage tolerance per swap or per liquidity add/remove
- Introduce a config contract or upgradeable pattern to manage default parameters

### 🧩 Multi-Pair Support

- Generalize the contract to support **any token pair**, not just USDT/DAI
- Fetch tokens dynamically or via constructor inputs

### 🔄 Support for Auto-Reinvestment or Zapping

- Automatically reinvest LP tokens or rewards
- Implement a **zap-in** and **zap-out** function for one-click liquidity provisioning/removal

### 🧠 Gas Optimization

- Use custom memory structs and caching to reduce redundant external calls
- Optimize token approvals using EIP-2612 (`permit` support)

### 🧪 Improved Testing & Coverage

- Add fuzz testing and property-based tests
- Cover more edge cases and reversion paths
- Include performance benchmarks for swaps and liquidity ops

### 🌐 Multi-DEX Support

- Add compatibility with other DEXs (e.g., SushiSwap, Balancer, Curve)
- Implement routing logic to select the best DEX based on price and liquidity

### 🔁 Upgradeability

- Use `UUPS` or `Transparent Proxy` pattern to enable upgrades without redeploying
- Separate storage and logic layers for long-term maintainability


## 📬 License

This project is released under the MIT License.


## 👨🏽‍💻 Author

This project has been developed by Guillermo Pastor [gpastor.kuster@gmail.com](mailto:gpastor.kuster@gmail.com).
