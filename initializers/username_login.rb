# frozen_string_literal: true

# Username Login Initializer
# This initializer modifies the login page to use "username" field instead of "email"
# when AUTO_EMAIL_DOMAIN is set. The username field can accept either:
# 1. A full email address (username@domain.com)
# 2. Just a username (which will be appended with AUTO_EMAIL_DOMAIN)

Rails.application.config.after_initialize do
  Rails.logger.info "=== Username Login Initializer Starting ==="
  
  # Check if auto-email-domain is set
  auto_email_domain = ENV['AUTO_EMAIL_DOMAIN']
  
  if auto_email_domain.present?
    Rails.logger.info "Username login enabled (AUTO_EMAIL_DOMAIN=#{auto_email_domain})"
    
    # Override User.find_for_authentication to handle username login.
    #
    # Guarded: after_initialize re-runs on every code reload under
    # RAILS_ENV=development, and re-aliasing would make
    # original_find_for_authentication point at the override, recursing until
    # SystemStackError on the next login attempt.
    if User.singleton_class.method_defined?(:original_find_for_authentication)
      Rails.logger.debug 'Username login override already installed, skipping re-alias'
    else
      User.class_eval do
        class << self
          # Override find_for_authentication to transform username to email
          alias_method :original_find_for_authentication, :find_for_authentication

          def find_for_authentication(conditions = nil)
            # Transform email if needed
            if conditions.is_a?(Hash) && conditions[:email].present? && !conditions[:email].include?('@')
              # SITE SPECIFIC: Default fallback to 'mail.lan' if AUTO_EMAIL_DOMAIN not set
              email_domain = ENV['AUTO_EMAIL_DOMAIN'] || 'mail.lan'
              username = conditions[:email]
              transformed_email = "#{username}@#{email_domain}"

              # Log transformation only in debug mode
              Rails.logger.debug { "Username login: '#{username}' -> '#{transformed_email}'" }

              # Call original with transformed email, then put the caller's
              # hash back the way we found it
              conditions[:email] = transformed_email
              begin
                original_find_for_authentication(conditions)
              ensure
                conditions[:email] = username
              end
            else
              original_find_for_authentication(conditions)
            end
          end
        end
      end
    end

    # Make config/locales/custom/*.yml win over the stock locale files.
    #
    # Rails globs config/locales/**/*.yml into I18n.load_path, and later files
    # override earlier ones -- but the glob puts custom/en.yml *before*
    # devise.en.yml, so our drop-in silently loses. Moving it to the end of
    # the load path and reloading is what actually makes it an override.
    #
    # (I18n.backend.store_translations here would not work either: the backend
    # loads lazily on the first lookup, which happens after this initializer,
    # and that load overwrites anything stored beforehand.)
    custom_locales = Dir[Rails.root.join('config', 'locales', 'custom', '*.yml')].sort
    if custom_locales.any?
      I18n.load_path -= custom_locales
      I18n.load_path += custom_locales
      I18n.reload!
      Rails.logger.info "Custom locale overrides moved to end of I18n.load_path: #{custom_locales.inspect}"
    end
  end
end

