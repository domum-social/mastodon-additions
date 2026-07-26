# Mailer URL Overrides for Onion Site
# This initializer ensures all outgoing emails use onion URLs instead of clearnet URLs
# It works by overriding the mailer methods and intercepting email generation
# 
# Environment variables used:
# - WEB_DOMAIN: The clearnet domain to replace (e.g., example.domain.com)
# - ONION_URL: The onion URL to replace with (e.g., example1234567890abcdefghijklmnopqrstuvwxyz.onion)
# 
# If ONION_URL is not defined, no URL rewriting will occur.
# If WEB_DOMAIN is not defined, we fall back to Rails.configuration.x.web_domain

Rails.application.config.after_initialize do
  Rails.logger.info "=== Mailer Override Initializer Starting ==="
  
  # Check if we should enable URL rewriting
  clearnet_host = ENV['WEB_DOMAIN'] || Rails.configuration.x.web_domain
  onion_url = ENV['ONION_URL']
  
  Rails.logger.info "Environment check:"
  Rails.logger.info "  ENV['WEB_DOMAIN'] = #{ENV['WEB_DOMAIN']}"
  Rails.logger.info "  ENV['ONION_URL'] = #{ENV['ONION_URL']}"
  Rails.logger.info "  Rails.configuration.x.web_domain = #{Rails.configuration.x.web_domain}"
  Rails.logger.info "  Final clearnet_host = #{clearnet_host}"
  
  if clearnet_host && onion_url
    Rails.logger.info "URL rewriting enabled: #{clearnet_host} -> #{onion_url}"
    
    # Boot-time diagnostics for when a Mastodon upgrade moves mailer methods
    Rails.logger.debug { "Devise::Mailer methods: #{Devise::Mailer.instance_methods(false)}" }
    Rails.logger.debug { "UserMailer methods: #{UserMailer.instance_methods(false)}" }
    
    # Override ActionMailer::Base to intercept all email generation
    ActionMailer::Base.class_eval do
      # Store the original mail method
      alias_method :original_mail, :mail

      # Forward positional args, keyword args AND the block. Mastodon calls
      # mail both as `mail(to:, subject:)` and as `mail(...) do |format|`;
      # a bare `def mail(*args)` silently swallows both under Ruby 3+.
      def mail(*args, **kwargs, &block)
        Rails.logger.debug { "ActionMailer::Base#mail called for #{self.class.name}" }

        # Call the original mail method using alias
        message = original_mail(*args, **kwargs, &block)

        # Process the message to replace URLs
        replace_urls_in_message(message)

        message
      end

      private

      # Rewrite clearnet URLs to onion URLs in every part of the message.
      #
      # Logging here is deliberately at debug: this runs on every outgoing
      # email and previously shipped subject lines to syslog.
      def replace_urls_in_message(message)
        # Get the current values each time to ensure they're fresh
        clearnet_host = ENV['WEB_DOMAIN'] || Rails.configuration.x.web_domain
        onion_url = ENV['ONION_URL']

        return if clearnet_host.blank? || onion_url.blank?

        rewrite = lambda do |body|
          body.to_s
              .gsub("https://#{clearnet_host}", "http://#{onion_url}")
              .gsub("http://#{clearnet_host}", "http://#{onion_url}")
        end

        Rails.logger.debug do
          "Rewriting #{clearnet_host} -> #{onion_url} in mail from #{self.class.name}"
        end

        # Replace URLs in the email body (both HTML and text parts)
        message.html_part.body = rewrite.call(message.html_part.body) if message.html_part
        message.text_part.body = rewrite.call(message.text_part.body) if message.text_part

        # If no parts, replace in the main body
        message.body = rewrite.call(message.body) if !message.html_part && !message.text_part
      end
    end

    # Log that the mailer overrides are loaded
    Rails.logger.info "=== Mailer URL overrides loaded - clearnet URLs will be replaced with onion URLs in emails only ==="
  else
    if !clearnet_host
      Rails.logger.warn "WEB_DOMAIN not defined and Rails.configuration.x.web_domain not available, URL rewriting disabled"
    end
    if !onion_url
      Rails.logger.warn "ONION_URL not defined, URL rewriting disabled"
    end
    Rails.logger.info "=== Mailer URL overrides disabled - no environment variables configured ==="
  end
end
