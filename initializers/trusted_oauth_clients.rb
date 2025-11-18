# frozen_string_literal: true

# Trusted OAuth Clients Initializer
# This initializer extends Doorkeeper's skip_authorization to support
# a list of trusted OAuth client IDs that can be configured via environment variables.
#
# When a user authorizes a trusted OAuth client, they do not need to provide
# consent on first use - the authorization is automatically granted.

# Parse trusted OAuth client IDs from environment variable
TRUSTED_CLIENT_IDS = if ENV['TRUSTED_OAUTH_CLIENT_IDS'].present?
  ENV['TRUSTED_OAUTH_CLIENT_IDS'].split(',').map(&:strip).reject(&:blank?)
else
  []
end.freeze

Rails.logger.info "=== Trusted OAuth Clients Initializer ==="
Rails.logger.info "Found #{TRUSTED_CLIENT_IDS.length} trusted OAuth client ID(s):"
TRUSTED_CLIENT_IDS.each { |id| Rails.logger.info "  - #{id}" }

Rails.application.config.after_initialize do
  # Override the skip_authorization? method in OAuth::AuthorizationsController
  OAuth::AuthorizationsController.class_eval do
    def skip_authorization?
      # Call the original method first (for superapp check)
      original_result = super
      return true if original_result
      
      # Try to get the client from various possible sources
      client = nil
      
      # Try from @pre_auth
      client = @pre_auth&.client
      
      # Try from instance variables if @pre_auth doesn't have it
      unless client
        # Check if we can get it from the params
        if @pre_auth&.client_id
          client = Doorkeeper::Application.find_by(uid: @pre_auth.client_id)
        end
      end
      
      # Check if it's a trusted OAuth client
      if client && TRUSTED_CLIENT_IDS.include?(client.uid)
        Rails.logger.info "OAuth authorization automatically granted for trusted client '#{client.application.name}' (UID: #{client.uid})"
        return true
      end
      
      false
    end
  end
  
  Rails.logger.info "=== Trusted OAuth Clients patch applied ==="
end

