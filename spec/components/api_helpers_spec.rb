require "rails_helper"

describe MozillaGCM::APIHelpers do
  subject { Class.new { include MozillaGCM::APIHelpers }.new }

  describe "get_users_and_create_staged" do
    it "returns users" do
      user = Fabricate(:user)
      staged_user = Fabricate(:staged)
      user_with_secondary = Fabricate(:user_with_secondary_email)
      MozillaIAM::Profile.expects(:find_or_create_user_from_uid_and_secondary_emails).with("uid1").returns(user)
      MozillaIAM::Profile.expects(:find_or_create_user_from_uid_and_secondary_emails).with("uid2").returns(staged_user)
      MozillaIAM::Profile.expects(:find_or_create_user_from_uid_and_secondary_emails).with("uid3").raises(MozillaIAM::Profile::EmailExistsError.new("email", user_with_secondary))
      result = subject.get_users_and_create_staged(["uid1", "uid2", "uid3"])
      expect(result).to match_array [user, staged_user, user_with_secondary]
    end
  end

end
