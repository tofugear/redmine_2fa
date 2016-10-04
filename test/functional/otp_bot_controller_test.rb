require File.expand_path('../../test_helper', __FILE__)

class OtpBotControllerTest < ActionController::TestCase
  fixtures :users, :email_addresses, :roles

  setup do
    @bot_token = '12345678:botSecretToken'
    Setting.create name: 'plugin_redmine_2fa', value: { 'bot_token' => @bot_token }
    Setting['host_name'] = 'redmine.test'
    @request             = ActionController::TestRequest.new

  end

  context 'init' do
    context 'authorized' do

      setup do
        @request.session[:user_id] = 1
      end

      should 'set webhook' do
        Telegrammer::Bot.any_instance.expects(:set_webhook).
            with('https://redmine.test/redmine_2fa/' + @bot_token + '/update')

        VCR.use_cassette('init') { post :create }
      end

      should 'set bot name and bot id' do
        plugin_settings      = Setting.find_by(name: 'plugin_redmine_2fa')
        plugin_settings_hash = plugin_settings.value

        assert plugin_settings_hash['bot_name'].nil?
        assert plugin_settings_hash['bot_id'].nil?

        VCR.use_cassette('init') { post :create }

        plugin_settings.reload
        plugin_settings_hash = plugin_settings.value

        assert_not plugin_settings_hash['bot_name'].nil?
        assert_not plugin_settings_hash['bot_id'].nil?
      end

      should 'redirect to plugin_settings_path' do
        VCR.use_cassette('init') { post :create }
        assert_redirected_to plugin_settings_path('redmine_2fa')
      end
    end

    context 'unauthorized' do

      should 'return unauthorized status' do
        post :create
        assert_redirected_to signin_path
      end

    end


  end

  context 'reset' do
    context 'authorized' do
      setup do
        Telegrammer::Bot.any_instance.stubs(:get_me)
        Telegrammer::Bot.any_instance.expects(:set_webhook).with('')
        @request.session[:user_id] = 1
      end

      should 'deactivate telegram accounts' do
        telegram_account = Redmine2FA::TelegramAccount.create active: true

        delete :destroy

        telegram_account.reload

        assert !telegram_account.active
      end

      should 'redirect to plugin_settings_path' do
        delete :destroy
        assert_redirected_to plugin_settings_path('redmine_2fa')
      end
    end


    context 'unauthorized' do

      should 'return unauthorized status' do
        delete :destroy
        assert_redirected_to signin_path
      end

    end

  end


end
