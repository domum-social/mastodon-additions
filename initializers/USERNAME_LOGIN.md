# Username Login Feature

## Overview

This feature modifies the Mastodon login page to accept a "username" field instead of "email" when `AUTO_EMAIL_DOMAIN` is configured. This makes the login experience simpler for users in environments where email addresses follow a predictable pattern.

## How It Works

When `AUTO_EMAIL_DOMAIN` is set in the environment, the login form allows users to enter either:

1. **A full email address**: `username@domain.com` - Used as-is for authentication
2. **Just a username**: `username` - Automatically converted to `username@AUTO_EMAIL_DOMAIN` for authentication

## Example

If `AUTO_EMAIL_DOMAIN=example.com` is set:

- User enters `alice` → Converted to `alice@example.com` for login
- User enters `alice@example.com` → Used as-is for login
- User enters `alice@otherdomain.com` → Used as-is for login (external email)

## Configuration

Add to your `env.production` file:

```bash
# Note: If not set, defaults to 'mail.lan' which is site-specific
AUTO_EMAIL_DOMAIN=example.com
```

This initializer will automatically:

1. Accept `username` parameter in addition to `email` parameter
2. Transform usernames without `@` symbols to include the `AUTO_EMAIL_DOMAIN`
3. Pass full email addresses (with `@`) through unchanged

## Frontend Change Required

For the UI to display "username" instead of "email", you need to create a custom view. This initializer only handles the backend authentication logic - the form parameter can still be named "email" but will accept and process username-style inputs.

Alternatively, if you modify the login view to use a `username` field instead of `email`, this initializer will automatically map it to the email parameter.

## Technical Details

- The transformation happens in `User.find_for_authentication` at the model level
- When a username without '@' is provided, it's automatically transformed to `username@AUTO_EMAIL_DOMAIN` before database lookup
- Full email addresses (with '@') are used as-is
- Users are still looked up by email address internally
- The authentication key remains the email field in the User model
- This works seamlessly with existing password, 2FA, and other authentication mechanisms
- Error messages are customized to say "username" instead of "email" for better UX

## Relationship to Auto Email Confirmation

This feature works alongside the `auto_email_confirm.rb` initializer:

- Both use the `AUTO_EMAIL_DOMAIN` environment variable
- Auto Email Confirmation handles account creation
- Username Login handles account authentication
- Together, they provide a simplified user experience without requiring users to know or manage their email addresses

