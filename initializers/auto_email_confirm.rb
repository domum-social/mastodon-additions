# Auto Email Confirmation Override
# This initializer modifies the account creation workflow to:
# 1) Automatically set email to $username@<AUTO_EMAIL_DOMAIN> (defaults to mail.lan if not set - SITE SPECIFIC)
# 2) Skip email confirmation without sending email
# 3) Hide the email field from the signup form

Rails.application.config.after_initialize do
  Rails.logger.info "=== Auto Email Confirm Initializer Starting ==="
  
  # Check if auto-email-confirmation is enabled
  auto_email_enabled = ENV['AUTO_EMAIL_CONFIRMATION'] == 'true'
  # SITE SPECIFIC: Default fallback to 'mail.lan' if AUTO_EMAIL_DOMAIN not set
  auto_email_domain = ENV['AUTO_EMAIL_DOMAIN'] || 'mail.lan'
  
  Rails.logger.info "Environment check:"
  Rails.logger.info "  ENV['AUTO_EMAIL_CONFIRMATION'] = #{ENV['AUTO_EMAIL_CONFIRMATION']}"
  Rails.logger.info "  ENV['AUTO_EMAIL_DOMAIN'] = #{ENV['AUTO_EMAIL_DOMAIN']}"
  Rails.logger.info "  auto_email_enabled = #{auto_email_enabled}"
  Rails.logger.info "  auto_email_domain = #{auto_email_domain}"
  
  if auto_email_enabled
    Rails.logger.info "Auto email confirmation enabled"
    
    # Override Auth::RegistrationsController to modify email during user creation
    Auth::RegistrationsController.class_eval do
      # Override build_resource to set email from username
      alias_method :original_build_resource, :build_resource
      
      def build_resource(hash = nil)
        # SITE SPECIFIC: Default fallback to 'mail.lan' if AUTO_EMAIL_DOMAIN not set
        Rails.logger.info "build_resource called with email domain: #{ENV['AUTO_EMAIL_DOMAIN'] || 'mail.lan'}"
        
        # Call original to build the resource
        original_build_resource(hash)
        
        # Set email based on username if email is not already set
        if resource.email.blank? && resource.account&.username.present?
          # SITE SPECIFIC: Default fallback to 'mail.lan' if AUTO_EMAIL_DOMAIN not set
          email_domain = ENV['AUTO_EMAIL_DOMAIN'] || 'mail.lan'
          resource.email = "#{resource.account.username}@#{email_domain}"
          Rails.logger.info "Auto-set email to: #{resource.email}"
        elsif params[:user].present? && params[:user][:email].present?
          # Even if user provides email, override it
          # SITE SPECIFIC: Default fallback to 'mail.lan' if AUTO_EMAIL_DOMAIN not set
          email_domain = ENV['AUTO_EMAIL_DOMAIN'] || 'mail.lan'
          resource.email = "#{resource.account.username}@#{email_domain}"
          Rails.logger.info "Override email to: #{resource.email}"
        end
        
        # Skip confirmation
        if resource.persisted? == false # Only skip if new record
          Rails.logger.info "Calling skip_confirmation! on user resource"
          resource.skip_confirmation!
        end
      end
      
      # Override create to ensure confirmation is skipped
      alias_method :original_create, :create
      
      def create
        Rails.logger.info "create action called"
        result = original_create
        
        # If user was created successfully, skip confirmation
        if resource.persisted? && resource.respond_to?(:skip_confirmation!)
          Rails.logger.info "User created successfully, ensuring confirmation is skipped"
          resource.skip_confirmation!
          resource.confirmed_at ||= Time.now.utc if resource.new_record? == false
          resource.save if resource.changed?
          
          # Disable user-facing email notifications but keep moderation notifications enabled
          Rails.logger.info "Disabling user-facing email notifications for new user (keeping moderation notifications enabled)"
          
          # Reload user to ensure we have the latest settings from the database
          resource.reload if resource.persisted?
          
          # Update settings
          resource.settings.update(
            'notification_emails.follow' => false,
            'notification_emails.reblog' => false,
            'notification_emails.favourite' => false,
            'notification_emails.mention' => false,
            'notification_emails.follow_request' => false,
            # Keep moderation notifications enabled for staff
            'notification_emails.report' => true,
            'notification_emails.pending_account' => true,
            'notification_emails.appeal' => true,
            # Disable non-essential notifications
            'notification_emails.trends' => false,
            'notification_emails.software_updates' => 'none',
            'always_send_emails' => false
          )
          
          # Save the updated settings
          resource.save!
          
          Rails.logger.info "Updated notification settings for user #{resource.email}"
        end
        
        result
      end
      
    end
    
    # Prevent Devise from sending confirmation emails
    # by overriding the notification sending
    User.class_eval do
      def send_confirmation_notifications
        Rails.logger.info "send_confirmation_notifications called - skipping (auto-email-confirmation enabled)"
        # Do nothing - don't send confirmation email
      end
    end
    
    # Also override the devise confirmable module's send_confirmation_instructions
    User.class_eval do
      def send_confirmation_instructions
        Rails.logger.info "send_confirmation_instructions called - skipping (auto-email-confirmation enabled)"
        # Do nothing - don't send confirmation email
        self.confirmation_token = Devise.friendly_token
        self.confirmation_sent_at = Time.now.utc
        save(validate: false) if persisted?
      end
    end
    
    # Prevent sending of confirmation emails by clearing pending notifications
    User.class_eval do
      alias_method :original_send_pending_devise_notifications, :send_pending_devise_notifications
      
      def send_pending_devise_notifications
        # Don't send any confirmation-related emails
        pending_devise_notifications.delete_if { |notification, *, **| 
          [:confirmation_instructions, :reconfirmation_instructions].include?(notification)
        }
        
        original_send_pending_devise_notifications
      end
    end
    
    Rails.logger.info "=== Auto email confirmation overrides loaded ==="
  else
    Rails.logger.info "Auto email confirmation disabled - set AUTO_EMAIL_CONFIRMATION=true to enable"
  end
end
