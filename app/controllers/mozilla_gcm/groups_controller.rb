module MozillaGCM
  class GroupsController < ApplicationController
    before_action :insert_group_if_allowed

    def create
      return render json: {}, status: 400 unless params[:name]

      short_name = UserNameSuggester.fix_username User.normalize_username("#{@client.namespace} #{params[:name]}")

      group = Group.new(
        name: short_name,
        full_name: params[:name],
        bio_raw: params[:description]
      )

      if params[:users]
        group.users = get_users_and_create_staged params[:users]
      end

      group.save!

      render json: { id: group.id, discourse_group_name: group.name }, status: 201
    end

    def show
      user_ids = @group.users.map do |user|
        MozillaIAM::Profile.for(user)&.uid
      end.reject(&:blank?)

      render json: { name: @group.full_name, description: @group.bio_raw, users: user_ids, discourse_group_name: @group.name }, status: 200
    end

    def update
      if params[:name]
        @group.name = UserNameSuggester.fix_username User.normalize_username("#{@client.namespace} #{params[:name]}")
        @group.full_name = params[:name]
      end
      if params[:description]
        @group.bio_raw = params[:description]
      end
      if params[:users]
        users = get_users_and_create_staged(params[:users])
        (@group.users - users).each { |u| @group.remove(u) }
        users.each { |u| @group.add(u) }
      end

      @group.save!

      render json: { discourse_group_name: @group.name }, status: 200
    end

    def destroy
      @group.destroy!
      render json: {}, status: 200
    end

    def modify_users
      if params[:add]
        get_users_and_create_staged(params[:add]).each { |u| @group.add(u) }
      end
      if params[:remove]
        get_users_and_create_staged(params[:remove]).each { |u| @group.remove(u) }
      end
      @group.save!
      render json: {}, status: 200
    end

    private

    def insert_group_if_allowed
      if params[:id]
        group = Group.find(params[:id])
        if group.name.start_with? "#{@client.namespace}_"
          @group = group
        else
          render json: {}, status: 403
        end
      end
    end

  end
end
