# Mastodon Code Overrides

This repository contains custom code overrides and modifications for the [Domum Social](https://domum.social) Mastodon instance. These overrides extend Mastodon's functionality with custom features, theming, and view modifications.

They are presented here for transparency and as examples. This is not likely something you can just drop in place on another site.

## Overview

### Implemented Features

- **Auto Email Confirmation**: Automatically sets user emails to `$username@<AUTO_EMAIL_DOMAIN>` and skips email confirmation without sending confirmation emails
- **Username Login**: Allows users to log in with just their username (without the domain) when `AUTO_EMAIL_DOMAIN` is configured
- **Mailer URL Overrides**: Rewrites clearnet URLs to onion URLs in all outgoing emails for Tor hidden service support
- **Trusted OAuth Clients**: Allows certain OAuth applications to skip the consent screen for seamless integration
- **Custom Themes**: Domum-branded dark and light themes with custom color palettes and styling
- **Custom Footer Component**: Adds a "Learning site" link to the footer navigation

### Repository Contents

This repository includes:
- **Rails Initializers**: Custom behavior modifications for authentication, email handling, and OAuth
- **Custom Themes**: Branded themes with SCSS styling
- **View Overrides**: Modified HAML templates for authentication pages
- **Component Overrides**: React/TypeScript component customizations
- **Dockerfiles**: Custom Docker images for production and development

## Repository Structure

```
.
├── initializers/          # Rails initializers for custom behavior
│   ├── auto_email_confirm.rb          # Auto email confirmation feature
│   ├── AUTO_EMAIL_CONFIRMATION.md     # Documentation for auto email confirmation
│   ├── username_login.rb              # Username-based login feature
│   ├── USERNAME_LOGIN.md              # Documentation for username login
│   ├── mailer_overrides.rb            # Mailer URL rewriting for onion sites
│   ├── trusted_oauth_clients.rb      # Trusted OAuth client feature
│   └── TRUSTED_OAUTH_CLIENTS.md      # Documentation for trusted OAuth clients
├── theming/               # Custom themes and styling
│   ├── styles/            # SCSS theme files
│   ├── locales/           # Theme name localizations
│   ├── themes.yml         # Theme configuration
│   └── README.md          # Theming documentation
├── views/                 # HAML view overrides
│   └── auth/              # Authentication view overrides
│       ├── registrations/ # Registration form views
│       └── sessions/      # Login form views
├── components/            # React/TypeScript component overrides
│   └── app/javascript/mastodon/features/ui/components/
│       └── link_footer.tsx
├── Dockerfile             # Production Dockerfile
├── Dockerfile.dev         # Development Dockerfile
└── README.md              # This file
```

## Components

### Initializers

#### Auto Email Confirmation (`auto_email_confirm.rb`)
Automatically sets user emails to `$username@<AUTO_EMAIL_DOMAIN>` and skips email confirmation without sending confirmation emails.

**Environment Variables:**
- `AUTO_EMAIL_CONFIRMATION` - Set to `true` to enable this feature
- `AUTO_EMAIL_DOMAIN` - Email domain to use (defaults to `mail.lan` if not set - **SITE SPECIFIC**)

**Documentation:** See [initializers/AUTO_EMAIL_CONFIRMATION.md](initializers/AUTO_EMAIL_CONFIRMATION.md)

#### Username Login (`username_login.rb`)
Modifies the login page to accept a "username" field instead of "email" when `AUTO_EMAIL_DOMAIN` is configured.

**Environment Variables:**
- `AUTO_EMAIL_DOMAIN` - Email domain for username transformation (defaults to `mail.lan` if not set - **SITE SPECIFIC**)

**Documentation:** See [initializers/USERNAME_LOGIN.md](initializers/USERNAME_LOGIN.md)

#### Mailer Overrides (`mailer_overrides.rb`)
Ensures all outgoing emails use onion URLs instead of clearnet URLs by rewriting URLs in email content.

**Environment Variables:**
- `WEB_DOMAIN` - The clearnet domain to replace (e.g., `example.domain.com`)
- `ONION_URL` - The onion URL to replace with (e.g., `example1234567890abcdefghijklmnopqrstuvwxyz.onion`)

**Documentation:** See inline comments in the file

#### Trusted OAuth Clients (`trusted_oauth_clients.rb`)
Allows certain OAuth applications to be marked as "trusted", meaning users do not need to provide consent when authorizing these applications.

**Environment Variables:**
- `TRUSTED_OAUTH_CLIENT_IDS` - Comma-separated list of OAuth client UIDs

**Documentation:** See [initializers/TRUSTED_OAUTH_CLIENTS.md](initializers/TRUSTED_OAUTH_CLIENTS.md)

### Theming

The `theming/` directory contains custom themes for [Domum Social](https://domum.social)

**Documentation:** See [theming/README.md](theming/README.md)

### View Overrides

The `views/` directory contains HAML template overrides for authentication pages:
- `auth/registrations/new.html.haml` - Signup form
- `auth/registrations/edit.html.haml` - Account settings
- `auth/sessions/new.html.haml` - Login form

These views are conditionally modified based on environment variables (e.g., `AUTO_EMAIL_CONFIRMATION`).

### Component Overrides

The `components/` directory contains React/TypeScript component overrides:
- `link_footer.tsx` - Custom footer component with additional links

### Dockerfiles

- `Dockerfile` - Production Dockerfile with asset precompilation
- `Dockerfile.dev` - Development Dockerfile with development gems and on-demand asset compilation

## Configuration

### Required Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AUTO_EMAIL_CONFIRMATION` | Enable auto email confirmation | `false` |
| `AUTO_EMAIL_DOMAIN` | Email domain for auto-generated emails | `mail.lan` |
| `WEB_DOMAIN` | Clearnet domain for mailer URL rewriting | None |
| `ONION_URL` | Onion URL for mailer URL rewriting | None |
| `TRUSTED_OAUTH_CLIENT_IDS` | Comma-separated OAuth client UIDs | None |



