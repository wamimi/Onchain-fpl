# OnChain FPL - Learning Roadmap 🚀

## Overview
This project is designed to teach you production-grade Web3 development by building a real Fantasy Premier League betting platform on Base L2. You'll learn industry-standard tools and patterns used by top DeFi protocols.

---

## 🎯 Learning Objectives

By the end of this project, you will master:

### 1. **Smart Contract Optimization**
- Gas-efficient code patterns
- Avoiding common pitfalls (gas bombs, reentrancy, etc.)
- Scalability considerations for production
- Security best practices

### 2. **Chainlink Oracles**
- Chainlink Functions (fetch external API data)
- Chainlink Automation (scheduled contract execution)
- Decentralized oracle networks (DON)
- Request/callback pattern
- LINK token economics

### 3. **The Graph (Subgraph Development)**
- Event indexing and GraphQL queries
- Schema design for blockchain data
- Efficient querying patterns
- Alternative to expensive view functions

### 4. **Frontend Integration**
- Wagmi hooks for contract interaction
- Real-time data updates
- Multi-provider wallet support (WalletConnect, Coinbase, etc.)
- State management with TanStack Query

### 5. **Deployment & DevOps**
- Base L2 deployment
- Testnet → Mainnet migration
- Contract verification
- Monitoring and maintenance

---

## 📋 Phase-by-Phase Plan

### **Phase 1: Contract Enhancement** (Current Phase)

**What we're doing:**
- Review suggested contract improvements
- Identify good vs. bad patterns
- Add safe enhancements (avoid gas bombs)
- Fix missing state variables

**What you'll learn:**
- ✅ How to evaluate third-party code suggestions
- ✅ Gas optimization trade-offs
- ✅ When to use on-chain vs. off-chain computation
- ✅ Struct design for frontend integration

**Tasks:**
1. ✅ Analyze enhanced contracts (DONE!)
2. Add missing variables (`hasClaimed`, `totalClaimed`)
3. Add safe view functions (`getLeagueInfo`, `getUserStats`)
4. Add pagination to factory view functions
5. Write tests for new features
6. Commit changes (many small commits!)

**Timeline:** 1-2 days

---

### **Phase 2: Chainlink Oracle Integration**

**What we're building:**
An `FPLOracle.sol` contract that:
- Fetches FPL scores from external API
- Uses Chainlink Functions for decentralized data
- Automatically updates leagues weekly via Chainlink Automation
- Handles multiple leagues efficiently

**What you'll learn:**
- ✅ How oracles solve the "Oracle Problem"
- ✅ Chainlink Functions architecture
- ✅ Writing JavaScript source code for DON nodes
- ✅ Request/callback pattern in Solidity
- ✅ Chainlink Automation (Keepers)
- ✅ LINK token subscriptions and funding

**Research Phase (You):**
1. Read Chainlink Functions docs
2. Study FPL API structure
3. Understand Base Sepolia setup
4. Learn about DON (Decentralized Oracle Network)

**Implementation Phase (Together):**
1. Design FPLOracle contract architecture
2. Write JavaScript source code for FPL API
3. Implement request/callback in Solidity
4. Add Automation compatibility
5. Write tests with mocked Chainlink responses
6. Deploy to Base Sepolia
7. Fund LINK subscription
8. Test with real FPL data

**Timeline:** 3-5 days

---

### **Phase 3: The Graph Subgraph**

**What we're building:**
A subgraph that indexes all league events and provides GraphQL API for:
- User dashboard (leagues joined, winnings, rankings)
- League discovery (filter by entry fee, status, etc.)
- Leaderboards (sorted by score)
- Historical data (past leagues, prize distributions)

**What you'll learn:**
- ✅ Why subgraphs are essential for scalable dApps
- ✅ GraphQL schema design
- ✅ Event-driven indexing
- ✅ Writing subgraph manifest and mappings
- ✅ Deploying to The Graph network
- ✅ Querying from frontend

**Architecture:**
```
Smart Contracts (Base L2)
    ↓ (emit events)
The Graph Indexer
    ↓ (processes events)
Subgraph (GraphQL API)
    ↓ (queries)
Frontend (React/Next.js)
```

**Tasks:**
1. Design GraphQL schema
2. Write subgraph manifest (`subgraph.yaml`)
3. Write mapping handlers (TypeScript)
4. Define entities (League, Participant, Prize, etc.)
5. Deploy to Subgraph Studio
6. Test queries
7. Integrate with frontend

**Timeline:** 2-3 days

---

### **Phase 4: Frontend Integration**

**What we're building:**
Complete frontend with:
- League creation wizard
- League discovery/filtering
- User dashboard
- Live leaderboards
- Prize claiming interface
- Real-time updates

**What you'll learn:**
- ✅ Wagmi contract hooks
- ✅ GraphQL integration with Apollo/URQL
- ✅ Real-time blockchain event listening
- ✅ Transaction state management
- ✅ Error handling and UX patterns

**Features to implement:**
1. **Create League Flow**
   - Form with validation
   - USDC approval transaction
   - League creation transaction
   - Success confirmation

2. **Join League Flow**
   - Browse active leagues
   - Filter by entry fee
   - USDC approval
   - Join transaction

3. **User Dashboard**
   - Active leagues
   - Pending winnings
   - Claim prizes
   - Historical data

4. **League Page**
   - Live leaderboard
   - Time remaining
   - Prize breakdown
   - Participant list

**Timeline:** 4-5 days

---

### **Phase 5: Testing & Deployment**

**What we're doing:**
- Comprehensive testing on Base Sepolia
- User acceptance testing
- Deploy to Base Mainnet
- Contract verification
- Monitoring setup

**What you'll learn:**
- ✅ Testnet deployment workflows
- ✅ Contract verification on Basescan
- ✅ Mainnet deployment checklists
- ✅ Post-deployment monitoring
- ✅ Incident response

**Tasks:**
1. End-to-end testing on Sepolia
2. Test oracle updates with real FPL data
3. Test subgraph indexing
4. Security audit checklist review
5. Deploy to Base Mainnet
6. Verify contracts on Basescan
7. Initialize oracle with LINK
8. Deploy subgraph to mainnet
9. Launch frontend

**Timeline:** 2-3 days

---

## 🛠️ Technology Stack

### Smart Contracts
- **Language:** Solidity 0.8.20
- **Framework:** Foundry (forge, cast)
- **Testing:** Forge tests with fuzzing
- **Libraries:** OpenZeppelin v5.x
- **Network:** Base L2 (Sepolia testnet → Mainnet)

### Oracle
- **Service:** Chainlink Functions + Automation
- **Language:** JavaScript (for DON nodes)
- **Payment:** LINK tokens
- **Data Source:** Fantasy Premier League API

### Indexing
- **Service:** The Graph
- **Language:** TypeScript (mappings)
- **Query Language:** GraphQL
- **Deployment:** Subgraph Studio → Decentralized Network

### Frontend
- **Framework:** Next.js 15 (App Router)
- **Wallet:** Reown AppKit, OnchainKit, MiniKit
- **State:** Wagmi + TanStack Query
- **Styling:** Tailwind CSS
- **Data:** Apollo Client (GraphQL)

---

## 📚 Learning Resources

### Chainlink
- [Chainlink Functions Docs](https://docs.chain.link/chainlink-functions)
- [Chainlink Automation Docs](https://docs.chain.link/chainlink-automation)
- [Functions Tutorials](https://docs.chain.link/chainlink-functions/tutorials)
- [Base + Chainlink](https://www.chainlinkecosystem.com/ecosystem/base)

### The Graph
- [The Graph Docs](https://thegraph.com/docs/)
- [Subgraph Studio](https://thegraph.com/studio/)
- [GraphQL Tutorial](https://graphql.org/learn/)
- [AssemblyScript (mapping language)](https://www.assemblyscript.org/)

### Base L2
- [Base Docs](https://docs.base.org/)
- [Base Sepolia Faucet](https://www.coinbase.com/faucets/base-ethereum-goerli-faucet)
- [Basescan](https://basescan.org/)

### Foundry
- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Testing](https://book.getfoundry.sh/forge/tests)
- [Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/)

### Fantasy Premier League
- [FPL API Docs (Unofficial)](https://github.com/vaastav/Fantasy-Premier-League)
- [FPL API Endpoints](https://fantasy.premierleague.com/api/bootstrap-static/)

---

## 🎓 Key Concepts You'll Master

### 1. The Oracle Problem
**Problem:** Blockchains can't access external data directly.
**Solution:** Chainlink's decentralized oracle network.
**You'll learn:** How multiple nodes reach consensus on off-chain data.

### 2. Pull Payment Pattern
**Problem:** Sending funds in a loop can fail.
**Solution:** Let users claim their own prizes.
**You'll learn:** Why this is safer and more gas-efficient.

### 3. Event-Driven Architecture
**Problem:** View functions become expensive at scale.
**Solution:** Emit events, index with subgraph, query efficiently.
**You'll learn:** How to design events for frontend consumption.

### 4. Gas Optimization
**Problem:** Every operation costs gas.
**Solution:** Minimize storage writes, use immutable, pack variables.
**You'll learn:** How to write production-grade gas-efficient code.

### 5. Access Control Patterns
**Problem:** Who can call sensitive functions?
**Solution:** OpenZeppelin's AccessControl with roles.
**You'll learn:** Role-based permissions (ORACLE_ROLE, CREATOR_ROLE, etc.).

---

## 📊 Success Metrics

By the end, you'll have:

- ✅ **3 production-ready smart contracts** (League, LeagueFactory, FPLOracle)
- ✅ **Comprehensive test suite** (50+ tests with >90% coverage)
- ✅ **Live Chainlink oracle** fetching real FPL data
- ✅ **Deployed subgraph** indexing all events
- ✅ **Full-stack dApp** with great UX
- ✅ **Portfolio project** showcasing advanced Web3 skills
- ✅ **Deep understanding** of oracle networks and data indexing

---

## 🚀 Next Steps

### Immediate (Today):
1. ✅ Finish reviewing enhanced contracts (DONE!)
2. Decide which enhancements to keep
3. Create new branch: `feat/contract-enhancements`
4. Start implementing safe improvements
5. Write tests as we go

### This Week:
1. Complete contract enhancements
2. Merge PR with many commits
3. Start Chainlink research
4. Read ORACLE_INTEGRATION.md
5. Study FPL API structure

### Next Week:
1. Build FPLOracle contract
2. Test on Base Sepolia
3. Start subgraph design
4. Plan frontend integration

---

## 💪 Why This Approach Works

1. **Learn by Building:** Not just tutorials - real production code
2. **Industry Standards:** Using tools that actual DeFi protocols use
3. **Incremental Progress:** Small wins with many commits
4. **Best Practices:** Security, gas efficiency, scalability
5. **Portfolio Ready:** Showcase to employers/community

---

## 🤝 Collaboration Approach

**You focus on:**
- Research (Chainlink docs, FPL API, The Graph)
- Running tests and builds
- Git commits (many small ones!)
- High-level decisions

**I'll help with:**
- Code implementation
- Architecture decisions
- Debugging issues
- Best practices guidance
- Optimization suggestions

---

Let's build something amazing! 🔥

Ready to start Phase 1 enhancements?
