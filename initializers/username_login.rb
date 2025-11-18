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
    
    # Override User.find_for_authentication to handle username login
    User.class_eval do
      class << self
        # Override find_for_authentication to transform username to email
        alias_method :original_find_for_authentication, :find_for_authentication
        
        def find_for_authentication(conditions = nil)
          # Transform email if needed
          if conditions.is_a?(Hash) && conditions[:email].present? && !conditions[:email].include?('@')
            # SITE SPECIFIC: Default fallback to 'mail.lan' if AUTO_EMAIL_DOMAIN not set
            email_domain = ENV['AUTO_EMAIL_DOMAIN'] || 'mail.lan'
            transformed_email = "#{conditions[:email]}@#{email_domain}"
            
            # Log transformation only in debug mode
            Rails.logger.debug "Username login: '#{conditions[:email]}' -> '#{transformed_email}'"
            
            # Call original with transformed email
            conditions[:email] = transformed_email
            result = original_find_for_authentication(conditions)
            
            # Restore original email
            conditions[:email] = conditions[:email].sub("@#{email_domain}", '')
            
            result
          else
            original_find_for_authentication(conditions)
          end
        end
      end
    end
    
    # Override I18n translations for error messages to use "username" instead of "email"
    if defined?(I18n)
      I18n.backend.store_translations(:en, devise: {
        failure: {
          invalid: "Invalid username or password.",
          not_found_in_database: "Invalid username or password."
        }
      }, override: true)
    end
  end
end

