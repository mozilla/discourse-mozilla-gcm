require "rails_helper"

# Rails.logger = Logger.new(STDOUT)
# Rails.logger.level = Logger::ERROR

def create_clients(parent_category = Fabricate(:category))
  MozillaGCM::Client.create(name: "Test", namespace: "test", key: "12345", category: parent_category)
  MozillaGCM::Client.create(name: "Some Other", namespace: "some", key: "not_test", category: Fabricate(:category))
end

def check_user_subscribed(user, category, level = :watching)
  category_user = CategoryUser.where(category: category, user: user).first
  expect(category_user).to be
  expect(category_user.notification_level).to eq CategoryUser.notification_levels[level]
end

def query_api(params: {}, headers: {})
  process(method, path, params: params, headers: {"X-API-KEY": "12345"}.merge(headers), as: :json)
end

shared_examples "verify_api_key" do
  describe "#verify_api_key" do
    it "fails with invalid api key" do
      query_api headers: {"X-API-KEY": "123"}
      expect(response.status).to eq(401)
    end

    it "succeeds with a valid api key" do
      query_api headers: {"X-API-KEY": "12345"}
      expect(response.status).to_not eq(401)
    end
  end
end
