
FileUtils.mkdir_p(Rails.root.join('log/redmine_2fa')) unless Dir.exist?(Rails.root.join('log/redmine_2fa'))

require 'redmine_2fa'

if Redmine2FA.require_redmine_bot?
  require_dependency Rails.root.join('plugins','redmine_bots', 'init')  
  require 'telegram/bot'
end 

# Rails 5.1/Rails 4
reloader = defined?(ActiveSupport::Reloader) ? ActiveSupport::Reloader : ActionDispatch::Reloader

reloader.to_prepare do
  %w( /app/models/redmine_2fa/*.rb
      /app/models/redmine_2fa/auth_source/*.rb
      /lib/redmine_2fa/patches/account_controller_patch/*.rb
      /lib/redmine_2fa/*.rb
      /lib/redmine_2fa/code_sender/*.rb
      /lib/redmine_2fa/{patches/*_patch,hooks/*_hook,*}.rb).each do |paths|
    Dir.glob(File.dirname(__FILE__) + paths).each do |file|
      require_dependency file
    end
  end
end

Redmine::Plugin.register :redmine_2fa do
  name 'Redmine 2FA'
  version '1.7.1'
  url 'https://github.com/centosadmin/redmine_2fa'
  description 'Two-factor authorization for Redmine'
  author 'Southbridge'
  author_url 'https://github.com/centosadmin/redmine_2fa'

  requires_redmine version_or_higher: '3.0'

  if Redmine2FA.require_redmine_bot?
    requires_redmine_plugin :redmine_bots, '0.2.0'
  end 

  # Default no active protocol specified, need to turn on

  settings(default: { 'required' => false,
                      'active_protocols' => %w(none)
  },
           partial: 'settings/redmine_2fa')
end
