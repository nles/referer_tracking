class RefererTracking::Sweeper < ActionController::Caching::Sweeper
  def after_create(record)
    if session && session["referer_tracking"]
      ses = session["referer_tracking"]

      ref_mod = RefererTracking::RefererTracking.new(
          :trackable_id => record.id, :trackable_type => record.class.to_s)

      ses.each_pair do |key, value|
        ref_mod[key] = value if ref_mod.has_attribute?(key)
      end

      req = assigns(:referer_tracking_request_add_infos)
      if req && req.is_a?(Hash)
        req.each_pair do |key, value|
          ref_mod[key] = value if ref_mod.has_attribute?(key)
        end
      end

      ref_mod[:ip] = request.ip
      ref_mod[:user_agent] = request.env['HTTP_USER_AGENT']
      ref_mod[:current_request_url] = request.url
      ref_mod[:current_request_referer_url] = request.env["HTTP_REFERER"] # or request.headers["HTTP_REFERER"]
      ref_mod[:session_id] = request.session["session_id"]

      if RefererTracking.save_cookies
        begin
          ref_mod[:cookies_yaml] = cookies.instance_variable_get('@cookies').to_yaml
        rescue
          str = "referer_tracking after create problem encoding cookie yml, probably non utf8 chars #{e}"
          logger.error(str)
          ref_mod[:cookies_yaml] = "error: #{str}"
        end
      end

      ref_mod.save
    end

  rescue Exception => e
    Rails.logger.info "RefererTracking::Sweeper.after_create problem with creating record: #{e}"
  end
end

