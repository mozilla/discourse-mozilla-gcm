module MozillaGCM
  class UsersController < ApplicationController

    def show
      user = MozillaIAM::Profile.find_by_uid(params[:id])&.user
      return render json: {}, status: 404 unless user

      groups = user.groups.filter do |g|
        g.name.starts_with? "#{@client.namespace}_"
      end.map { |g| g.id }

      render json: {
        username: user.username,
        url: "#{Discourse.base_url}/u/#{user.username}",
        groups: groups
      }, status: 200
    end

  end
end
