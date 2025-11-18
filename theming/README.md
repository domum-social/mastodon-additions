# Mastodon Custom Themes

This directory contains custom themes for the Domum Social Mastodon instance.

## Current Themes
- **domum-dark**: Dark theme with deep charcoal backgrounds and golden highlights
- **domum-light**: Light theme with clean design using warm neutrals and golden accents
- **domum-social**: Shared theme components and assets (icons, variables)

## File Structure
```
theming/
├── styles/           # Theme SCSS files
│   ├── domum-dark/   # Dark theme files
│   ├── domum-light/  # Light theme files
│   └── domum-social/ # Shared theme components
├── themes.yml        # Theme configuration
└── locales/          # Theme name localizations
```

## Installation
Themes are automatically installed during Docker image build via the Dockerfile, which copies theme files to the appropriate locations in the Mastodon container.
