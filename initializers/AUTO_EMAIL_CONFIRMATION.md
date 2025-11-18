# Auto Email Confirmation Feature

This feature automatically sets user emails to `$username@<AUTO_EMAIL_DOMAIN>` (or a custom domain) and skips email confirmation without sending confirmation emails.

**Note:** If `AUTO_EMAIL_DOMAIN` is not set, the code defaults to `mail.lan` which is site-specific and should be configured via environment variable.

## How It Works

### 1. Automatic Email Generation
When a user signs up with username `alice`, their email is automatically set to `alice@<AUTO_EMAIL_DOMAIN>`.

### 2. Email Confirmation Skipped
The user is automatically confirmed without needing to verify their email address. No confirmation email is sent.

### 3. Email Field Hidden
The email field is hidden from the signup form on the onion site using JavaScript, so users cannot manually edit their email address.

## Configuration

Set these environment variables in your `.env.production` file:

```bash
# Enable auto email confirmation
AUTO_EMAIL_CONFIRMATION=true

# Optional: Set custom email domain (default: mail.lan - SITE SPECIFIC)
# If not set, defaults to 'mail.lan' which is site-specific
AUTO_EMAIL_DOMAIN=example.com
```

## Files Modified

1. **Initializer**: `mastodon/initializers/auto_email_confirm.rb`
   - Overrides `Auth::RegistrationsController` to set email from username
   - Skips Devise email confirmation
   - Prevents confirmation emails from being sent

2. **View Overrides**: 
   - `mastodon/views/auth/registrations/new.html.haml` - Signup form
   - `mastodon/views/auth/registrations/edit.html.haml` - Account settings
   - Both conditionally hide the email field when `AUTO_EMAIL_CONFIRMATION=true`
   - Add hidden fields with auto-generated email values

3. **Docker Compose**: `compose-include/core-services.yml`
   - Mounts the initializer file into the web and sidekiq containers

4. **Dockerfile**: `mastodon/Dockerfile`
   - Copies view overrides to the container during build

## How It Works

### Initializer (auto_email_confirm.rb)

The initializer patches the following:

1. `Auth::RegistrationsController#build_resource`:
   - Sets email to `username@<AUTO_EMAIL_DOMAIN>` before user creation (defaults to `mail.lan` if not set - SITE SPECIFIC)
   - Calls `skip_confirmation!` to mark user as confirmed

2. `Auth::RegistrationsController#create`:
   - Ensures user is confirmed after creation
   - Sets `confirmed_at` timestamp
   - **Disables user-facing email notifications** (follow, reblog, favourite, mention, follow_request)
   - **Keeps moderation email notifications enabled** (report, pending_account, appeal)
   - Disables non-essential notifications (trends, software_updates)
   - Sets `always_send_emails` to `false`

3. `User#send_confirmation_notifications` and `User#send_confirmation_instructions`:
   - Prevents Devise from sending any confirmation emails

4. `User#send_pending_devise_notifications`:
   - Filters out confirmation-related notifications from the pending notifications queue

### View Overrides

Both signup and account settings views check for `ENV['AUTO_EMAIL_CONFIRMATION'] == 'true'` and:
- Hide the visible email input field
- Add hidden fields with auto-generated email values
- Display email as read-only or completely hidden to prevent changes
- No JavaScript needed - pure server-side rendering

## Usage

Once configured with `AUTO_EMAIL_CONFIRMATION=true`, users signing up through the onion site will:
1. Enter a username
2. Set a password
3. Have their email automatically set to `username@<AUTO_EMAIL_DOMAIN>` (defaults to `mail.lan` if not set - SITE SPECIFIC)
4. Be immediately confirmed without needing to verify their email

## Note

This feature is specifically designed for the onion site where account signup occurs. The clearnet site blocks authentication URLs entirely.

