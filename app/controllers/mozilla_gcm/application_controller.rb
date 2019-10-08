module MozillaGCM
  class ApplicationController < ActionController::Base
    include APIHelpers
    before_action :verify_api_key

    def verify_api_key
      key = request.headers["x-api-key"]
      client = Client.find_by(key: key)
      if client
        @client = client
      else
        render json: {}, status: 401
      end
    end

  end
end
