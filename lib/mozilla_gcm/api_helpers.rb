module MozillaGCM
  module APIHelpers

    def get_users_and_create_staged(ids)
      ids.map do |id|
        begin
          MozillaIAM::Profile.find_or_create_user_from_uid_and_secondary_emails(id)
        rescue MozillaIAM::Profile::EmailExistsError => e
          e.user
        end
      end
    end

  end
end
