# frozen_string_literal: true

# shamelessly adapted from https://github.com/discourse/discourse/blob/4e4844f4dbcbab50502f9feb973dbd13c6a75246/app/controllers/admin/site_settings_controller.rb#L54-L71
task "mozilla_gcm:mute_all_externally_managed_categories" => :environment do
  notification_level = NotificationLevels.all[:muted]
  categories = MozillaGCM::Client.all.pluck(:category_id).map {|x| Category.find(x).subcategories.pluck(:id) }.flatten

  CategoryUser.where(category_id: categories, notification_level: notification_level).delete_all

  categories.each do |category_id|
    skip_user_ids = CategoryUser.where(category_id: category_id).pluck(:user_id)

    User.where.not(id: skip_user_ids).select(:id).find_in_batches do |users|
      category_users = []
      users.each { |user| category_users << { category_id: category_id, user_id: user.id, notification_level: notification_level } }
      CategoryUser.insert_all!(category_users)
    end
  end
end
