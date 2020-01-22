module MozillaGCM
  class CategoriesController < ApplicationController
    before_action :insert_category_if_allowed
    before_action :insert_groups_if_allowed
    before_action :insert_existing_groups

    def create
      return render json: {}, status: 400 unless params[:name]

      category = Category.new(
        name: params[:name],
        parent_category: @client.category,
        user: Discourse.system_user,
        description: params[:description],
      )

      category.save!

      # shamelessly adapted from https://github.com/discourse/discourse/blob/4e4844f4dbcbab50502f9feb973dbd13c6a75246/app/controllers/admin/site_settings_controller.rb#L54-L71
      User.select(:id).find_in_batches do |users|
        category_users = []
        users.each { |user| category_users << { category_id: category.id, user_id: user.id, notification_level: NotificationLevels.all[:muted] } }
        CategoryUser.insert_all!(category_users)
      end

      DistributedMutex.synchronize("mozilla_gcm_default_categories_muted") do
        SiteSetting.default_categories_muted = [SiteSetting.default_categories_muted, category.id].reject(&:blank?).join("|")
      end

      @groups&.each do |group|
        ::GroupCategoryNotification.add(group, category)
      end

      render json: { id: category.id, url: Discourse.base_url + category.url, email_in: category.email_in }, status: 201
    end

    def show
      render json: {
        name: @category.name,
        description: @category.description,
        url: Discourse.base_url + @category.url,
        groups: @existing_groups.map { |g| g.id },
        email_in: @category.email_in
      }, status: 200
    end

    def update
      if params[:name]
        @category.slug = nil
        @category.name = params[:name]
      end
      if params[:description]
        @category.topic.posts.first.update(raw: params[:description])
        @category.description = params[:description]
      end

      @groups&.each do |group|
        ::GroupCategoryNotification.add(group, @category)
      end
      (@existing_groups - Array(@groups)).each do |group|
        ::GroupCategoryNotification.remove(group, @category)
      end

      @category.save!

      render json: { url: Discourse.base_url + @category.url, email_in: @category.email_in }, status: 200
    end

    def destroy
      @category.slug = nil
      @category.name = "#{@category.parent_category.name}/#{@category.name}"
      @category.parent_category = Category.find_by_slug("archives")
      @category.save!

      CategoryGroup.create!(
        category: @category,
        group: Group.find(Group::AUTO_GROUPS[:everyone]),
        permission_type: CategoryGroup.permission_types[:readonly]
      )

      render json: {}, status: 200
    end

    private

    def insert_category_if_allowed
      if params[:id]
        category = Category.find(params[:id])
        if category.parent_category == @client.category
          @category = category
        else
          render json: {}, status: 403
        end
      end
    end

    def insert_groups_if_allowed
      if params[:groups]
        @groups = params[:groups].map do |group_id|
          group = Group.find(group_id)
          if group.name.starts_with?("#{@client.namespace}_")
            group
          else
            return render json: {}, status: 403
          end
        end
      end
    end

    def insert_existing_groups
      return unless @category
      @existing_groups = ::Group.all.filter do |group|
        group.custom_fields["default_categories_watching"]&.include?(@category.id) &&
          group.name.starts_with?("#{@client.namespace}_")
      end
    end
  end
end
