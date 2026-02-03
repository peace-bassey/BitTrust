# BitTrust DeFi Lending Protocol

[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-purple)](https://www.stacks.co/)
[![Clarity](https://img.shields.io/badge/Clarity-Smart_Contract-blue)](https://clarity-lang.org/)
[![Bitcoin](https://img.shields.io/badge/Bitcoin-Secured-orange)](https://bitcoin.org/)

## 🚀 Overview

BitTrust is an innovative Bitcoin-secured lending ecosystem that revolutionizes decentralized finance by creating a merit-based lending platform where borrowers earn better terms through proven repayment history. Built on the Stacks blockchain, it leverages Bitcoin's security while enabling advanced DeFi functionality through STX token collateralization.

### Key Features

- **🏆 Reputation-Based Lending**: Dynamic risk assessment that rewards financial responsibility
- **📊 Adaptive Pricing**: Real-time adjustment of collateral requirements and interest rates
- **🔒 Bitcoin Security**: Built on Stacks for Bitcoin-level security guarantees  
- **🎯 Merit-Based System**: Better terms for borrowers with proven repayment history
- **🔄 Self-Sustaining Ecosystem**: Incentivizes responsible borrowing behavior

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Smart Contract Functions](#-smart-contract-functions)
- [Reputation System](#-reputation-system)
- [Risk Assessment Engine](#-risk-assessment-engine)
- [Testing](#-testing)
- [Deployment](#-deployment)
- [Contributing](#-contributing)
- [Security](#-security)
- [License](#-license)

## 🏗 Architecture

### Core Components

1. **User Reputation System**: Tracks borrower creditworthiness and payment history
2. **Loan Management**: Comprehensive loan lifecycle management
3. **Risk Assessment Engine**: Dynamic collateral and interest rate calculation
4. **Collateral Management**: Secure STX token collateralization

### Data Structures

#### UserScores Map

```clarity
{
  score: uint,           // Reputation score (50-100)
  total-borrowed: uint,  // Lifetime borrowed amount
  total-repaid: uint,    // Lifetime repaid amount
  loans-taken: uint,     // Total number of loans
  loans-repaid: uint,    // Successfully repaid loans
  last-update: uint      // Last score update block height
}
```

#### Loans Map

```clarity
{
  borrower: principal,   // Loan recipient
  amount: uint,          // Loan amount in STX
  collateral: uint,      // Collateral amount in STX
  due-height: uint,      // Repayment due block height
  interest-rate: uint,   // Interest rate percentage
  is-active: bool,       // Active loan status
  is-defaulted: bool,    // Default status
  repaid-amount: uint    // Amount repaid so far
}
```

## 🚀 Getting Started

### Prerequisites

- [Clarinet CLI](https://github.com/hirosystems/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/kentomson01/BitTrust.git
   cd BitTrust
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Check contract syntax**

   ```bash
   clarinet check
   ```

4. **Run tests**

   ```bash
   npm test
   ```

### Quick Start

1. **Initialize your reputation score**

   ```clarity
   (contract-call? .BitTrust initialize-score)
   ```

2. **Request a loan**

   ```clarity
   (contract-call? .BitTrust request-loan u1000000 u1500000 u1440) ;; 1 STX loan, 1.5 STX collateral, ~1 day duration
   ```

3. **Repay the loan**

   ```clarity
   (contract-call? .BitTrust repay-loan u1 u1050000) ;; Repay loan #1 with interest
   ```

## 📖 Smart Contract Functions

### Public Functions

#### `initialize-score`

Establishes baseline creditworthiness for new protocol participants.

- **Parameters**: None
- **Returns**: `(response bool uint)`
- **Initial Score**: 50 (minimum threshold)

#### `request-loan`

Creates new lending agreement with personalized terms based on reputation.

```clarity
(request-loan (amount uint) (collateral uint) (duration uint))
```

- **Requirements**:
  - Minimum reputation score of 70
  - Maximum 5 active loans per user
  - Valid amount and duration
  - Sufficient collateral based on reputation

#### `repay-loan`

Handles partial and full loan payments while updating creditworthiness.

```clarity
(repay-loan (loan-id uint) (amount uint))
```

- **Features**:
  - Partial payments supported
  - Automatic reputation boost on full repayment
  - Collateral release on completion

#### `mark-loan-defaulted`

Administrative function for processing loan defaults (owner only).

```clarity
(mark-loan-defaulted (loan-id uint))
```

### Read-Only Functions

#### `get-user-score`

```clarity
(get-user-score (user principal))
```

Returns comprehensive user reputation profile.

#### `get-loan`

```clarity
(get-loan (loan-id uint))
```

Retrieves detailed loan information.

#### `get-user-active-loans`

```clarity
(get-user-active-loans (user principal))
```

Lists user's current active loan portfolio.

## 🏆 Reputation System

### Score Mechanics

- **Initial Score**: 50 points (minimum threshold)
- **Maximum Score**: 100 points
- **Loan Eligibility**: Minimum 70 points required
- **Score Updates**:
  - **+2 points** for successful loan repayment
  - **-10 points** for loan default

### Benefits by Score Range

| Score Range | Collateral Ratio | Interest Rate | Max Loans |
|-------------|------------------|---------------|-----------|
| 70-79       | ~95-90%         | 8-9%          | 5         |
| 80-89       | ~85-80%         | 6-7%          | 5         |
| 90-100      | ~75-50%         | 5-6%          | 5         |

## ⚖️ Risk Assessment Engine

### Dynamic Collateral Calculation

```clarity
collateral-ratio = 100 - (score × 50 / 100)
required-collateral = (loan-amount × collateral-ratio) / 100
```

### Interest Rate Determination

```clarity
interest-rate = base-rate - (score × 5 / 100)
// Base rate: 10%
// Score 70: 6.5% interest
// Score 100: 5% interest
```

### Risk Factors

1. **Reputation Score**: Primary risk indicator
2. **Loan History**: Track record of repayments
3. **Active Loans**: Debt-to-capacity ratio
4. **Market Conditions**: Dynamic rate adjustments

## 🧪 Testing

### Run Test Suite

```bash
npm test                    # Run all tests
npm run test:report        # Generate coverage report
npm run test:watch         # Watch mode for development
```

### Test Categories

- **Unit Tests**: Individual function testing
- **Integration Tests**: End-to-end workflow testing
- **Edge Cases**: Boundary condition validation
- **Security Tests**: Attack vector prevention

### Example Test Structure

```typescript
import { describe, it, expect } from 'vitest';
import { Cl } from '@stacks/transactions';

describe('BitTrust Protocol', () => {
  it('should initialize user score correctly', () => {
    // Test implementation
  });
  
  it('should calculate collateral requirements based on reputation', () => {
    // Test implementation
  });
});
```

## 🚀 Deployment

### Testnet Deployment

1. **Configure network**

   ```bash
   clarinet settings set devnet
   ```

2. **Deploy contract**

   ```bash
   clarinet deploy --testnet
   ```

3. **Verify deployment**

   ```bash
   clarinet console --testnet
   ```

### Mainnet Deployment

```bash
clarinet deploy --mainnet
```

### Environment Configuration

Update `settings/` directory files:

- `Devnet.toml`: Local development settings
- `Testnet.toml`: Testnet configuration  
- `Mainnet.toml`: Production settings

## 🤝 Contributing

We welcome contributions to the BitTrust protocol! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for new functionality
4. Implement changes with proper documentation
5. Ensure all tests pass (`npm test`)
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

### Code Standards

- Follow Clarity best practices
- Maintain test coverage >90%
- Document all public functions
- Use meaningful variable names
- Include error handling

## 🔒 Security

### Security Features

- **Access Control**: Owner-only administrative functions
- **Input Validation**: Comprehensive parameter checking
- **State Management**: Secure state transitions
- **Error Handling**: Graceful failure handling
- **Overflow Protection**: Safe arithmetic operations

### Audit Status

- [ ] Internal Security Review
- [ ] External Audit (Planned)
- [ ] Formal Verification (Future)

### Reporting Security Issues

Please report security vulnerabilities to [security@bittrust.io](mailto:security@bittrust.io)

## 📊 Protocol Metrics

### Current Parameters

```clarity
MIN-SCORE: 50               // Minimum reputation threshold
MAX-SCORE: 100              // Maximum achievable reputation  
MIN-LOAN-SCORE: 70          // Minimum score for loan eligibility
MAX-LOAN-DURATION: 52560    // ~1 year (10-minute blocks)
MAX-ACTIVE-LOANS: 5         // Per user limit
```

### Economic Model

- **Collateral Range**: 50-95% of loan value
- **Interest Rates**: 5-9% annually
- **Loan Duration**: 1 block to 1 year
- **Reputation Incentive**: Better terms for higher scores

## 🛣 Roadmap

### Phase 1: Core Protocol ✅

- [x] Basic lending functionality
- [x] Reputation system
- [x] Risk assessment engine
- [x] Test suite

### Phase 2: Enhanced Features 🚧

- [ ] Liquidation mechanisms
- [ ] Multi-asset collateral support
- [ ] Flash loans
- [ ] Governance token

### Phase 3: Advanced DeFi 📋

- [ ] Yield farming integration
- [ ] Cross-chain compatibility
- [ ] Insurance protocols
- [ ] DAO governance

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Stacks Blockchain](https://www.stacks.co/)
- [Clarity Language](https://clarity-lang.org/)
