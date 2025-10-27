# OnChain FPL Frontend

A Next.js application for the OnChain FPL platform, built with OnchainKit, Reown AppKit (WalletConnect), and MiniKit for Farcaster integration.

## Tech Stack

- **Framework**: Next.js 15 (App Router)
- **Blockchain**: Base L2
- **Wallet Integration**:
  - Reown AppKit (WalletConnect) - for universal wallet support
  - OnchainKit - for Coinbase wallet and onchain components
  - MiniKit - for Farcaster miniapp functionality
- **State Management**: Wagmi + TanStack Query
- **Styling**: CSS Modules

## Getting Started

### 1. Install Dependencies

```bash
npm install
```

### 2. Environment Setup

Create a `.env.local` file based on `.env.example`:

```bash
cp .env.example .env.local
```

Then add your API keys:

- **WalletConnect Project ID**: Get from [Reown Dashboard](https://dashboard.reown.com)
- **OnchainKit API Key**: Get from [Coinbase Developer Portal](https://portal.cdp.coinbase.com/)

### 3. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## Features

### Wallet Connection
- Multi-wallet support via Reown AppKit (WalletConnect)
- Coinbase Smart Wallet integration
- Farcaster MiniApp support for in-app usage

### Base L2 Integration
- Optimized for Base mainnet and Sepolia testnet
- Low gas fees for transactions
- USDC stablecoin support

## Project Structure

```
frontend/onchainfpl/
├── app/                  # Next.js app router
│   ├── layout.tsx       # Root layout with providers
│   ├── page.tsx         # Home page
│   └── rootProvider.tsx # Combined provider setup
├── config/              # Configuration files
│   └── index.tsx        # Wagmi adapter config
├── public/              # Static assets
└── minikit.config.ts    # Farcaster miniapp config
```

## Key Integrations

### Reown AppKit (WalletConnect)
- Enables connection to 600+ wallets
- Provides universal wallet support
- Required for WalletConnect rewards eligibility

### OnchainKit
- Coinbase wallet components
- Transaction components
- Identity components

### MiniKit
- Farcaster miniapp integration
- In-app wallet support
- Social features

## Learn More

- [Next.js Documentation](https://nextjs.org/docs)
- [OnchainKit Docs](https://docs.base.org/onchainkit)
- [Reown AppKit Docs](https://docs.reown.com/appkit)
- [Wagmi Documentation](https://wagmi.sh)
- [Base Documentation](https://docs.base.org)
