require_relative "../spec_helper"

describe MozillaGCM::GroupsController do
  let(:user1) { Fabricate(:user) }
  let(:user2) { Fabricate(:user) }
  before do
    create_clients
    MozillaIAM::Profile.new(user1, "uid1")
    MozillaIAM::Profile.new(user2, "uid2")
  end

  describe "#create" do
    let(:method) { :post }
    let(:path) { "/mozilla_gcm/groups" }
    include_examples "verify_api_key"

    it "succeeds" do
      query_api params: {
        name: "Tea Lovers",
        description: "For those who love tea",
        users: ["uid1", "uid2"]
      }
      expect(response.status).to eq(201)
      body = JSON.parse(response.body)
      expect(body["discourse_group_name"]).to eq "test_tea_lovers"
      id = body["id"]
      group = Group.find(id)
      expect(group.name).to eq "test_tea_lovers"
      expect(group.full_name).to eq "Tea Lovers"
      expect(group.bio_raw).to eq "For those who love tea"
      expect(group.users).to match_array([user1, user2])
    end

    context "with no name" do
      it "fails" do
        query_api
        expect(response.status).to eq(400)
      end
    end
  end

  context "with group" do
    let(:category) { Fabricate(:category) }
    let(:group) { Fabricate(:group, name: "test_tea_lovers",
                                    full_name: "Tea Lovers",
                                    bio_raw: "For those who love tea",
                                    users: [user1, user2]) }
    before { GroupCategoryNotification.add(group, category) }
    let(:path) { "/mozilla_gcm/groups/#{group.id}" }

    shared_examples "insert_group_if_allowed" do
      describe "#insert_group_if_allowed" do
        it "returns forbidden" do
          query_api headers: {"X-API-KEY": "not_test"}
          expect(response.status).to eq 403
        end

        it "returns not found" do
          path.sub!(group.id.to_s, "1337")
          query_api
          expect(response.status).to eq 404
        end
      end
    end

    describe "#show" do
      let(:method) { :get }
      include_examples "verify_api_key"
      include_examples "insert_group_if_allowed"

      it "returns ok" do
        query_api
        expect(response.status).to eq 200
        body = JSON.parse(response.body)
        expect(body["name"]).to eq "Tea Lovers"
        expect(body["description"]).to eq "For those who love tea"
        expect(body["users"]).to match_array ["uid1", "uid2"]
        expect(body["discourse_group_name"]).to eq "test_tea_lovers"
      end
    end

    describe "#update" do
      let(:method) { :patch }
      include_examples "verify_api_key"
      include_examples "insert_group_if_allowed"

      it "returns ok" do
        query_api params: {
          name: "We Love Tea",
          description: "Say no to coffee",
          users: ["uid1"]
        }
        expect(response.status).to eq 200
        body = JSON.parse(response.body)
        expect(body["discourse_group_name"]).to eq "test_we_love_tea"
        group.reload
        expect(group.name).to eq "test_we_love_tea"
        expect(group.full_name).to eq "We Love Tea"
        expect(group.bio_raw).to eq "Say no to coffee"
        expect(group.users).to match_array [user1]
        check_user_subscribed(user1, category)
        check_user_subscribed(user2, category, :regular)
      end

      context "with only name" do
        it "returns ok" do
          query_api params: {
            name: "We Love Tea"
          }
          expect(response.status).to eq 200
          body = JSON.parse(response.body)
          expect(body["discourse_group_name"]).to eq "test_we_love_tea"
          group.reload
          expect(group.name).to eq "test_we_love_tea"
          expect(group.full_name).to eq "We Love Tea"
        end
      end

      context "with only description" do
        it "returns ok" do
          query_api params: {
            description: "Say no to coffee"
          }
          expect(response.status).to eq 200
          group.reload
          expect(group.bio_raw).to eq "Say no to coffee"
        end
      end

      context "with only users" do
        it "returns ok" do
          query_api params: {
            users: ["uid1"]
          }
          expect(response.status).to eq 200
          group.reload
          expect(group.users).to match_array [user1]
          check_user_subscribed(user1, category)
          check_user_subscribed(user2, category, :regular)
        end
      end
    end

    describe "#delete" do
      let(:method) { :delete }
      include_examples "verify_api_key"
      include_examples "insert_group_if_allowed"

      it "returns ok" do
        query_api
        expect(response.status).to eq 200
        expect { group.reload }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    describe "#modify_users" do
      let(:method) { :patch }
      let(:path) { "/mozilla_gcm/groups/#{group.id}/users" }
      include_examples "verify_api_key"
      include_examples "insert_group_if_allowed"

      let(:user3) { Fabricate(:user) }
      before { MozillaIAM::Profile.new(user3, "uid3") }

      it "returns ok" do
        query_api params: {
          add: ["uid3"],
          remove: ["uid2"]
        }
        expect(response.status).to eq 200
        group.reload
        expect(group.users).to match_array [user1, user3]
        check_user_subscribed(user1, category)
        check_user_subscribed(user2, category, :regular)
        check_user_subscribed(user3, category)
      end

      context "with only add" do
        it "returns ok" do
          query_api params: {
            add: ["uid3"]
          }
          expect(response.status).to eq 200
          group.reload
          expect(group.users).to match_array [user1, user2, user3]
          check_user_subscribed(user1, category)
          check_user_subscribed(user2, category)
          check_user_subscribed(user3, category)
        end
      end

      context "with only remove" do
        it "returns ok" do
          query_api params: {
            remove: ["uid2"]
          }
          expect(response.status).to eq 200
          group.reload
          expect(group.users).to match_array [user1]
          check_user_subscribed(user1, category)
          check_user_subscribed(user2, category, :regular)
        end
      end
    end
  end
end
