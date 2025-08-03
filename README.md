# Blockchain-Based Public Housing Quality and Tenant Rights Protection System

A comprehensive smart contract system built on the Stacks blockchain to ensure fair housing practices, automate inspections, monitor rent control compliance, and protect tenant rights.

## System Overview

This system consists of five interconnected smart contracts that work together to create a transparent, automated, and fair public housing management system:

### 1. Housing Inspection Automation Contract (`housing-inspection.clar`)
- Schedules and tracks safety and habitability inspections
- Manages inspector assignments and certifications
- Records inspection results and compliance status
- Automates follow-up inspection scheduling

### 2. Rent Control Compliance Monitoring Contract (`rent-control.clar`)
- Ensures landlords comply with rent stabilization regulations
- Tracks rent increases and validates against legal limits
- Monitors lease renewals and rent-controlled unit status
- Generates compliance reports for housing authorities

### 3. Tenant Complaint Resolution Contract (`complaint-resolution.clar`)
- Manages and tracks resolution of housing quality complaints
- Categorizes complaints by severity and type
- Tracks resolution timelines and outcomes
- Maintains complaint history for pattern analysis

### 4. Maintenance Request Prioritization Contract (`maintenance-priority.clar`)
- Ensures urgent repairs are completed promptly
- Prioritizes requests based on safety and habitability impact
- Tracks completion times and contractor performance
- Manages maintenance budgets and approvals

### 5. Fair Housing Enforcement Contract (`fair-housing.clar`)
- Monitors and prevents housing discrimination
- Tracks protected characteristic violations
- Manages fair housing complaints and investigations
- Maintains landlord compliance scores

## Key Features

- **Transparency**: All actions are recorded on the blockchain for public accountability
- **Automation**: Smart contracts automate routine processes and compliance checks
- **Immutable Records**: Housing history and compliance data cannot be tampered with
- **Real-time Monitoring**: Continuous tracking of housing conditions and compliance
- **Fair Enforcement**: Consistent application of housing laws and regulations

## Data Types and Structures

### Common Data Types
- `uint`: Unsigned integers for IDs, amounts, and timestamps
- `principal`: Stacks addresses for users, landlords, and inspectors
- `(string-ascii 50)`: Text fields for names and descriptions
- `(string-ascii 500)`: Longer text for detailed descriptions and notes

### Status Enumerations
- Inspection Status: pending, scheduled, completed, failed
- Complaint Status: open, investigating, resolved, closed
- Priority Levels: low, medium, high, emergency
- Compliance Status: compliant, warning, violation, suspended

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for contract deployment

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Testing

The system includes comprehensive tests using Vitest:
- Unit tests for each contract function
- Integration tests for cross-contract workflows
- Edge case and error condition testing

### Usage Examples

#### Schedule an Inspection
\`\`\`clarity
(contract-call? .housing-inspection schedule-inspection property-id inspector-principal)
\`\`\`

#### File a Complaint
\`\`\`clarity
(contract-call? .complaint-resolution file-complaint property-id complaint-type description)
\`\`\`

#### Submit Maintenance Request
\`\`\`clarity
(contract-call? .maintenance-priority submit-request property-id request-type description priority)
\`\`\`

## Contract Architecture

Each contract is designed to be:
- **Self-contained**: No cross-contract dependencies
- **Upgradeable**: Admin functions for system updates
- **Secure**: Proper access controls and validation
- **Efficient**: Optimized for gas costs and performance

## Compliance and Legal Framework

This system is designed to support compliance with:
- Fair Housing Act
- Local rent control ordinances
- Housing quality standards
- Tenant rights legislation
- Public housing regulations

## Contributing

Please read our contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
