# QA Automation Demo Project

This project demonstrates a PowerShell/Pester-based QA automation architecture for Azure resources, with CI/CD integration and best practices for quality engineers.

## Structure
- `src/` - PowerShell scripts and Pester tests
- `config/` - YAML configuration and fixtures
- `scripts/` - Utility scripts (e.g., for CI/CD)
- `docs/` - Documentation and slide content

## Key Concepts
- Data-driven testing with Pester
- Centralized Azure queries in DiscoveryPhase.ps1
- Fixtures for expected vs. actual validation
- AI-assisted fixture generation
- Reporting: Console, Azure DevOps, Xray Jira
- BDD-style test organization

See `docs/ARCHITECTURE.txt` for details.
