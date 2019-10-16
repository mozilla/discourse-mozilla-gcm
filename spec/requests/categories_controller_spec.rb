require_relative "../spec_helper"

describe MozillaGCM::CategoriesController do
  let(:user1) { Fabricate(:user) }
  let(:user2) { Fabricate(:user) }
  let(:group1) { Fabricate(:group, users: [user1], name: "test_group1") }
  let(:group2) { Fabricate(:group, users: [user2], name: "test_group2") }
  let(:parent_category) { Fabricate(:category, name: "Test") }

  before do
    create_clients(parent_category)
    class ::Category
      after_save do
        update_column(:email_in, "#{self.slug}@test.localhost")
      end
    end
  end

  shared_examples "insert_groups_if_allowed" do
    describe "#insert_groups_if_allowed" do
      it "returns forbidden" do
        query_api headers: {"X-API-KEY": "not_test"}, params: {
          groups: [group1.id, group2.id]
        }
        expect(response.status).to eq 403
      end

      it "returns not found" do
        query_api params: {
          groups: [1337]
        }
        expect(response.status).to eq 404
      end
    end
  end

  describe "#create" do
    let(:method) { :post }
    let(:path) { "/mozilla_gcm/categories" }
    include_examples "verify_api_key"
    include_examples "insert_groups_if_allowed"

    it "succeeds" do
      query_api params: {
        name: "Coffee Club",
        description: "Public discussion of the Coffee Club's activities",
        groups: [group1.id, group2.id]
      }
      expect(response.status).to eq 201
      body = JSON.parse(response.body)
      expect(body["email_in"]).to eq "coffee-club@test.localhost"
      expect(body["url"]).to eq "http://test.localhost/c/test/coffee-club"
      category = Category.find(body["id"])
      expect(category.name).to eq "Coffee Club"
      expect(category.slug).to eq "coffee-club"
      expect(category.description).to eq "Public discussion of the Coffee Club's activities"
      expect(category.topic.posts.first.raw).to eq "Public discussion of the Coffee Club's activities"
      expect(category.parent_category).to eq parent_category
      check_user_subscribed(user1, category)
      check_user_subscribed(user2, category)
      expect(category.suppress_from_latest).to eq true
    end

    context "with no name" do
      it "fails" do
        query_api
        expect(response.status).to eq(400)
      end
    end
  end

  context "with category" do
    let(:category) do
      Fabricate(:category, name: "Coffee Club",
                           description: "Public discussion of the Coffee Club's activities",
                           email_in: "coffee-club@test.localhost",
                           parent_category: parent_category)
    end
    let(:user3) { Fabricate(:user) }
    let(:group3) { Fabricate(:group, users: [user3], name: "some_group3") }
    before do
      category.skip_category_definition = false
      category.create_category_definition
      GroupCategoryNotification.add(group1, category)
      GroupCategoryNotification.add(group2, category)
      GroupCategoryNotification.add(group3, category)
    end
    let(:path) { "/mozilla_gcm/categories/#{category.id}" }

    shared_examples "insert_category_if_allowed" do
      describe "#insert_category_if_allowed" do
        it "returns forbidden" do
          query_api headers: {"X-API-KEY": "not_test"}
          expect(response.status).to eq 403
        end

        it "returns not found" do
          path.sub!(category.id.to_s, "1337")
          query_api
          expect(response.status).to eq 404
        end
      end
    end

    describe "#show" do
      let(:method) { :get }
      include_examples "verify_api_key"
      include_examples "insert_category_if_allowed"

      it "returns ok" do
        query_api
        expect(response.status).to eq 200
        body = JSON.parse(response.body)
        expect(body["name"]).to eq "Coffee Club"
        expect(body["description"]).to eq "Public discussion of the Coffee Club's activities"
        expect(body["groups"]).to match_array [group1.id, group2.id]
        expect(body["email_in"]).to eq "coffee-club@test.localhost"
        expect(body["url"]).to eq "http://test.localhost/c/test/coffee-club"
      end

      context "without existing groups" do
        it "returns ok" do
          GroupCategoryNotification.remove(group1, category)
          GroupCategoryNotification.remove(group2, category)
          query_api
          expect(response.status).to eq 200
        end
      end
    end

    describe "#update" do
      let(:method) { :patch }
      include_examples "verify_api_key"
      include_examples "insert_category_if_allowed"
      include_examples "insert_groups_if_allowed"

      it "returns ok" do
        query_api params: {
          name: "Tea Club",
          description: "Tea is better than coffee",
          groups: [group1.id]
        }
        expect(response.status).to eq 200
        body = JSON.parse(response.body)
        expect(body["email_in"]).to eq "tea-club@test.localhost"
        expect(body["url"]).to eq "http://test.localhost/c/test/tea-club"
        category.reload
        expect(category.name).to eq "Tea Club"
        expect(category.description).to eq "Tea is better than coffee"
        expect(category.topic.posts.first.raw).to eq "Tea is better than coffee"
        check_user_subscribed(user1, category)
        check_user_subscribed(user2, category, :regular)
      end

      context "only with title" do
        it "returns ok" do
          query_api params: {
            name: "Tea Club"
          }
          expect(response.status).to eq 200
          body = JSON.parse(response.body)
          expect(body["email_in"]).to eq "tea-club@test.localhost"
          expect(body["url"]).to eq "http://test.localhost/c/test/tea-club"
          category.reload
          expect(category.name).to eq "Tea Club"
        end
      end

      context "only with description" do
        it "returns ok" do
          query_api params: {
            description: "Tea is better than coffee"
          }
          expect(response.status).to eq 200
          category.reload
          expect(category.description).to eq "Tea is better than coffee"
        end
      end

      context "only with groups" do
        it "returns ok" do
          query_api params: {
            groups: [group1.id]
          }
          expect(response.status).to eq 200
          category.reload
          check_user_subscribed(user1, category)
          check_user_subscribed(user2, category, :regular)
        end
      end

      context "without existing groups" do
        it "returns ok" do
          GroupCategoryNotification.remove(group1, category)
          GroupCategoryNotification.remove(group2, category)
          query_api params: {
            name: "Tea Club",
            description: "Tea is better than coffee",
            groups: [group1.id]
          }
          expect(response.status).to eq 200
        end
      end
    end

    describe "#destroy" do
      let(:method) { :delete }
      include_examples "verify_api_key"
      include_examples "insert_category_if_allowed"

      let(:archives) { Fabricate(:category, name: "Archives") }
      before do
        archives.category_groups.build(group: Group.find(Group::AUTO_GROUPS[:everyone]),
                                           permission_type: CategoryGroup.permission_types[:readonly])
      end

      it "returns ok" do
        query_api
        expect(response.status).to eq 200
        category.reload
        expect(category.name).to eq "Test/Coffee Club"
        expect(category.url).to eq "/c/archives/test-coffee-club"
        category_group = category.category_groups.first
        expect(category_group.group.name).to eq "everyone"
        expect(category_group.permission_type).to eq CategoryGroup.permission_types[:readonly]
      end
    end

  end

end
