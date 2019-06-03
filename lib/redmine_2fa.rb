module Redmine2FA
  AVAILABLE_PROTOCOLS = %w(telegram sms google_auth none)

  def self.table_name_prefix
    'redmine_2fa_'
  end

  def self.set_locale
    I18n.locale = Setting['default_language']
  end

  def self.active_protocols
    Setting.plugin_redmine_2fa['active_protocols']
  end
  
  def self.require_redmine_bot?
    Redmine2FA.active_protocols.include?('telegram') || Redmine2FA.active_protocols.include?('sms')    
  end

  def self.switched_on?
    !switched_off?
  end

  def self.switched_off?
    active_protocols.size.zero? || active_protocols.size == 1 && active_protocols.include?('none')
  end

  def self.logger
    Logger.new(Rails.root.join('log', 'redmine_2fa', 'bot-update.log'))
  end

  module Configuration
    def self.configuration
      Redmine::Configuration['redmine_2fa']
    end

    def self.sms_command
      sms_command = configuration && configuration['sms_command']
      if sms_command
        configuration['sms_command']
      else
        (Rails.env.test?) ? '' : 'echo %{phone} %{password} %{expired_at}'
      end
    end
  end
end
