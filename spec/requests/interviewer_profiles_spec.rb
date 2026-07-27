require "rails_helper"

RSpec.describe "Interviewer profiles", type: :request do
  describe "GET /interviewer_profile" do
    it "redirects to the new form when the interviewer has no profile yet" do
      sign_in create(:user, :interviewer)
      get interviewer_profile_path
      expect(response).to redirect_to(new_interviewer_profile_path)
    end

    it "shows the interviewer's own profile data" do
      profile = create(:interviewer_profile, company: "Acme", title: "Staff Eng")
      sign_in profile.user

      get interviewer_profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Acme")
      expect(response.body).to include("Staff Eng")
    end
  end

  describe "GET /interviewer_profile/new" do
    it "is accessible to an interviewer without a profile yet" do
      sign_in create(:user, :interviewer)
      get new_interviewer_profile_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects to edit if the interviewer already has a profile" do
      profile = create(:interviewer_profile)
      sign_in profile.user

      get new_interviewer_profile_path

      expect(response).to redirect_to(edit_interviewer_profile_path)
    end

    it "is forbidden for a candidate" do
      sign_in create(:user, :candidate)
      get new_interviewer_profile_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /interviewer_profile" do
    it "creates the profile for the current interviewer and marks them profile-complete" do
      user = create(:user, :interviewer)
      sign_in user

      post interviewer_profile_path, params: {
        interviewer_profile: { expertise: "Ruby", company: "Acme", title: "Staff Eng", years_of_experience: 8 }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.profile_complete?).to be(true)
    end

    it "re-renders with errors when required fields are missing" do
      sign_in create(:user, :interviewer)

      post interviewer_profile_path, params: { interviewer_profile: { expertise: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /interviewer_profile/edit and PATCH" do
    it "lets an interviewer update their own profile" do
      profile = create(:interviewer_profile, title: "Senior Eng")
      sign_in profile.user

      get edit_interviewer_profile_path
      expect(response).to have_http_status(:ok)

      patch interviewer_profile_path, params: { interviewer_profile: { title: "Staff Eng" } }
      expect(response).to redirect_to(root_path)
      expect(profile.reload.title).to eq("Staff Eng")
    end
  end
end
