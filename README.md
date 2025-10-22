# OnChain FPL

A decentralized Fantasy Premier League betting platform built on Base L2, combining official FPL performance data with smart contract-based prize distribution.

## Project Structure

This is a monorepo containing:

- **`/contracts`** - Smart contracts built with Foundry (Solidity)
- **`/frontend`** - React/Next.js web application (coming soon)
- **`/backend`** - Oracle service for FPL data integration (coming soon)

## Overview

OnChain FPL enables users to:
- Create private leagues with customizable entry fees (USDC)
- Stake funds with automated prize distribution
- Receive payouts based on official FPL rankings
- Enjoy transparent, trustless competition on Base L2

## Tech Stack

- **Blockchain**: Base L2 (Ethereum Layer 2)
- **Smart Contracts**: Solidity + Foundry
- **Tokens**: USDC (Base native)
- **Oracle**: Chainlink (planned)
- **Frontend**: React/Next.js + OnchainKit
- **Wallet**: WalletConnect

## Getting Started

### Contracts

```bash
cd contracts
forge build
forge test
```

See [contracts/README.md](contracts/README.md) for detailed smart contract documentation.

## Development Roadmap

- [x] Phase 1: Foundry setup and project initialization
- [ ] Phase 2: Core league management contracts
- [ ] Phase 3: Oracle integration for FPL data
- [ ] Phase 4: Frontend development
- [ ] Phase 5: Testing and security audits
- [ ] Phase 6: Mainnet deployment

## Documentation

- [Base Documentation](https://docs.base.org)
- [Foundry Book](https://book.getfoundry.sh/)
- [FPL API](https://fantasy.premierleague.com/api/bootstrap-static/)

## License

MIT
