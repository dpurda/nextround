require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "redirects to sign in when not authenticated" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows a welcome message and a profile-incomplete notice for a candidate with no profile" do
      user = create(:user, :candidate, name: "Jane Candidate")
      sign_in user

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome, Jane Candidate")
      expect(response.body).to include("complete yet")
    end

    it "does not show the profile-incomplete notice once a candidate has a profile" do
      profile = create(:candidate_profile)
      sign_in profile.user

      get root_path

      expect(response.body).not_to include("complete yet")
    end

    it "does not show the profile-incomplete notice for an admin" do
      sign_in create(:user, :admin)

      get root_path

      expect(response.body).not_to include("complete yet")
    end
  end
end
