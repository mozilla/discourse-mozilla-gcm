require_relative "../spec_helper"

describe MozillaGCM::CategoriesController do
  let(:user) { Fabricate(:user) }
  let!(:group1) { Fabricate(:group, name: "test_tea_lovers", users: [user]) }
  let!(:group2) { Fabricate(:group, name: "some_other_tea", users: [user]) }
  before do
    MozillaIAM::Profile.new(user, "uid")
    create_clients
  end

  describe "#show" do
    let(:method) { :get }
    let(:path) { "/mozilla_gcm/users/uid" }
    include_examples "verify_api_key"

    it "returns ok" do
      query_api
      expect(response.status).to eq 200
      body = JSON.parse(response.body)
      expect(body["username"]).to eq user.username
      expect(body["url"]).to eq "http://test.localhost/u/#{user.username}"
      expect(body["groups"]).to match_array [group1.id]
    end

    it "returns not found" do
      path.sub!("uid", "not_a_user")
      query_api
      expect(response.status).to eq 404
    end
  end

end
