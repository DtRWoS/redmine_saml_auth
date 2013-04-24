require 'ruby-saml'

class SamlController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:consume]
  skip_before_filter :check_if_login_required

  def index
    settings = Account.get_saml_settings
    request = Onelogin::Saml::Authrequest.new
    redirect_to(request.create(settings))
  end

  def consume
    response          = Onelogin::Saml::Response.new(params[:SAMLResponse], :skip_conditions =>  true)
    response.settings = Account.get_saml_settings

	logger.info "User #{response.name_id} trying to login"
	#logger.info "Yaml of data from onelogin #{response.to_yaml}"
	logger.info "User as located #{User.find_by_login(response.name_id).to_yaml}"
	logger.info "Is Response From OneLogin Valid? #{response.is_valid?}"
	puts response.validate!
    if response.is_valid? && user = User.find_by_login(response.name_id)

      self.logged_user = user
      # generate a key and set cookie if autologin
      if params[:autologin] && Setting.autologin?
        token = Token.create(:user => user, :action => 'autologin')
        cookies[:autologin] = { :value => token.value, :expires => 1.year.from_now }
      end
      call_hook(:controller_account_success_authentication_after, {:user => user })
      redirect_back_or_default :controller => 'my', :action => 'page'

    else
      #invalid_credentials(user)  #Throws an Error
      error = l(:notice_account_invalid_creditentials)
    end
  end

  def complete
  end

  def fail
  end

end
