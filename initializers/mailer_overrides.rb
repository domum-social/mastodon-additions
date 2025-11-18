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
    
    # First, let's see what methods actually exist on our mailer classes
    Rails.logger.info "Devise::Mailer methods: #{Devise::Mailer.instance_methods(false)}"
    Rails.logger.info "UserMailer methods: #{UserMailer.instance_methods(false)}"
    
    # Override ActionMailer::Base to intercept all email generation
    ActionMailer::Base.class_eval do
      # Store the original mail method
      alias_method :original_mail, :mail
      
      def mail(*args)
        Rails.logger.info "ActionMailer::Base#mail called for #{self.class.name}"
        
        # Call the original mail method using alias
        message = original_mail(*args)
        
        Rails.logger.info "Email generated via ActionMailer::Base#mail, now replacing clearnet URLs with onion URLs"
        
        # Process the message to replace URLs
        replace_urls_in_message(message)
        
        message
      end
      
      private
      
      def replace_urls_in_message(message)
        # Get the current values each time to ensure they're fresh
        clearnet_host = ENV['WEB_DOMAIN'] || Rails.configuration.x.web_domain
        onion_url = ENV['ONION_URL']
        
        Rails.logger.info "Starting URL replacement in email"
        Rails.logger.info "  Current clearnet_host: #{clearnet_host}"
        Rails.logger.info "  Current onion_url: #{onion_url}"
        Rails.logger.info "Email subject: #{message.subject}"
        Rails.logger.info "Email has HTML part: #{message.html_part.present?}"
        Rails.logger.info "Email has text part: #{message.text_part.present?}"
        
        # Replace URLs in the email body (both HTML and text parts)
        if message.html_part
          Rails.logger.info "Processing HTML part of email"
          old_body = message.html_part.body.to_s
          Rails.logger.info "HTML body contains clearnet URLs: #{old_body.include?(clearnet_host)}"
          
          new_body = old_body.gsub(
            "https://#{clearnet_host}", "http://#{onion_url}"
          ).gsub(
            "http://#{clearnet_host}", "http://#{onion_url}"
          )
          
          message.html_part.body = new_body
          Rails.logger.info "HTML body now contains onion URLs: #{new_body.include?(onion_url)}"
        end
        
        if message.text_part
          Rails.logger.info "Processing text part of email"
          old_body = message.text_part.body.to_s
          Rails.logger.info "Text body contains clearnet URLs: #{old_body.include?(clearnet_host)}"
          
          new_body = old_body.gsub(
            "https://#{clearnet_host}", "http://#{onion_url}"
          ).gsub(
            "http://#{clearnet_host}", "http://#{onion_url}"
          )
          
          message.text_part.body = new_body
          Rails.logger.info "Text body now contains onion URLs: #{new_body.include?(onion_url)}"
        end
        
        # If no parts, replace in the main body
        if !message.html_part && !message.text_part
          Rails.logger.info "Processing main body of email"
          old_body = message.body.to_s
          Rails.logger.info "Main body contains clearnet URLs: #{old_body.include?(clearnet_host)}"
          
          new_body = old_body.gsub(
            "https://#{clearnet_host}", "http://#{onion_url}"
          ).gsub(
            "http://#{clearnet_host}", "http://#{onion_url}"
          )
          
          message.body = new_body
          Rails.logger.info "Main body now contains onion URLs: #{new_body.include?(onion_url)}"
        end
        
        Rails.logger.info "URL replacement complete"
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
