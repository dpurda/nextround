require "rails_helper"

RSpec.describe "Candidate profiles", type: :request do
  describe "GET /candidate_profile" do
    it "redirects to the new form when the candidate has no profile yet" do
      sign_in create(:user, :candidate)
      get candidate_profile_path
      expect(response).to redirect_to(new_candidate_profile_path)
    end

    it "shows the candidate's own profile data" do
      profile = create(:candidate_profile, current_role: "SWE", location: "Bucharest, RO")
      sign_in profile.user

      get candidate_profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SWE")
      expect(response.body).to include("Bucharest, RO")
    end
  end

  describe "GET /candidate_profile/new" do
    it "is accessible to a candidate without a profile yet" do
      sign_in create(:user, :candidate)
      get new_candidate_profile_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects to edit if the candidate already has a profile" do
      profile = create(:candidate_profile)
      sign_in profile.user

      get new_candidate_profile_path

      expect(response).to redirect_to(edit_candidate_profile_path)
    end

    it "is forbidden for an interviewer" do
      sign_in create(:user, :interviewer)
      get new_candidate_profile_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /candidate_profile" do
    it "creates the profile for the current candidate and marks them profile-complete" do
      user = create(:user, :candidate)
      sign_in user

      post candidate_profile_path, params: {
        candidate_profile: {
          phone: "555-0100", current_role: "SWE", target_role: "Senior SWE",
          education: "BS CS", location: "Bucharest, RO", years_of_experience: 3
        }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.profile_complete?).to be(true)
    end

    it "re-renders with errors when required fields are missing" do
      sign_in create(:user, :candidate)

      post candidate_profile_path, params: { candidate_profile: { phone: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /candidate_profile/edit and PATCH" do
    it "lets a candidate update their own profile" do
      profile = create(:candidate_profile, current_role: "SWE")
      sign_in profile.user

      get edit_candidate_profile_path
      expect(response).to have_http_status(:ok)

      patch candidate_profile_path, params: { candidate_profile: { current_role: "Staff SWE" } }
      expect(response).to redirect_to(root_path)
      expect(profile.reload.current_role).to eq("Staff SWE")
    end
  end
end
