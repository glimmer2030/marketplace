# Weijan Marketplace

A small plugin marketplace for Claude Code.

## Installation (Claude Code)

Register this marketplace:

```bash
/plugin marketplace add glimmer2030/marketplace
```

Install a plugin from this marketplace:

```bash
/plugin install weekly-report@glimmer2030/marketplace
/plugin install 5g-note-generator@glimmer2030/marketplace
```

## Available Plugins

### weekly-report
Generate weekly reports and log session work to ~/.work-log.md

Commands:
- `/summary` - Manually generate and save a work summary for the current session

### 5g-note-generator
Generate 5G/O-RAN technical learning notes

Commands:
- `/generate-5g-note` - Generate a 5G/O-RAN technical note in Traditional Chinese

## Verify

```text
/help
```
