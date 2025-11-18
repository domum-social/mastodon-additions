# Trusted OAuth Clients Feature

This feature allows certain OAuth applications to be marked as "trusted", meaning users do not need to provide consent when authorizing these applications for the first time.

## Use Case

This is designed for mail system integration (Roundcube webmail) to make it feel more integrated with the Mastodon instance. When users access the mail system for the first time, they won't see the OAuth consent screen - the authorization is automatically granted.

## How It Works

### 1. Configuration

Set the `TRUSTED_OAUTH_CLIENT_IDS` environment variable with a comma-separated list of OAuth client UIDs (not names, but the actual client_id from the OAuth application) in your `env.production` file:

```bash
# Example in compose-include/env.production
TRUSTED_OAUTH_CLIENT_IDS=abc123def456,xyz789ghi012
```

### 2. Automatic Authorization

When a user authorizes an OAuth application:
- If the application's UID is in the `TRUSTED_OAUTH_CLIENT_IDS` list, consent is automatically granted
- If the application is marked as a superapp (existing Mastodon functionality), consent is also automatically granted
- Otherwise, the user sees the normal consent screen

### 3. Integration with Existing Superapp Feature

This initializer extends Mastodon's existing `superapp` feature. An application is automatically granted authorization if:
1. It's marked as a superapp in the database (existing behavior), OR
2. Its UID is in the `TRUSTED_OAUTH_CLIENT_IDS` environment variable (new behavior)

## Files

1. **Initializer**: `mastodon/initializers/trusted_oauth_clients.rb`
   - Monkey-patches `OAuth::AuthorizationsController#skip_authorization?` method
   - Checks if client UID is in the trusted list
   - Extends the existing superapp functionality
   - Logs when automatic authorization is granted

2. **Mount Configuration**: `compose-include/core-services.yml`
   - Mounts the initializer into the web and sidekiq containers

## Finding Your OAuth Client UID

To find the UID (client_id) of your OAuth application:

1. **Via Rails console:**
   ```ruby
   Doorkeeper::Application.find_by(name: 'Your Application Name').uid
   ```

2. **Via database:**
   ```sql
   SELECT uid, name FROM oauth_applications WHERE name = 'Your Application Name';
   ```

3. **Via Mastodon UI:**
   - Go to Settings → Development
   - Find your application
   - The `Client ID` is the UID you need

## Security Considerations

- **Trust Carefully**: Only add OAuth applications to the trusted list that you fully trust, as users won't see the authorization screen
- **Scope Control**: Even trusted applications are still subject to scope restrictions defined when the application was created
- **Logging**: All automatic authorizations are logged for audit purposes

## Usage

1. Create an OAuth application in Mastodon (for example, for Roundcube)
2. Note the Client ID (UID)
3. Add it to the `TRUSTED_OAUTH_CLIENT_IDS` environment variable
4. Restart the Mastodon web and sidekiq containers
5. Users authorizing this application will no longer see the consent screen

## Example Setup for Mail System Integration

```bash
# In compose-include/env.production
TRUSTED_OAUTH_CLIENT_IDS=<your_roundcube_oauth_client_id>

# The initializer will log:
# === Trusted OAuth Clients Initializer ===
# Found 1 trusted OAuth client ID(s):
#   - <your_roundcube_oauth_client_id>
# === Trusted OAuth Clients patch applied ===
```

