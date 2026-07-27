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

    it "shows work experience and education entries" do
      profile = create(:candidate_profile, :with_cv_entries)
      sign_in profile.user

      get candidate_profile_path

      expect(response.body).to include("Backend Engineer")
      expect(response.body).to include("Acme Corp")
      expect(response.body).to include("MIT")
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
          location: "Bucharest, RO", years_of_experience: 3
        }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.profile_complete?).to be(true)
    end

    it "creates work experience and education entries via nested attributes" do
      user = create(:user, :candidate)
      sign_in user

      post candidate_profile_path, params: {
        candidate_profile: {
          phone: "555-0100", current_role: "SWE", target_role: "Senior SWE", location: "Bucharest, RO",
          work_experiences_attributes: {
            "0" => { company: "Acme", title: "Engineer", start_date: "2020-01-01" }
          },
          educations_attributes: {
            "0" => { institution: "MIT", degree: "BS", start_date: "2014-01-01", end_date: "2018-01-01" }
          }
        }
      }

      expect(response).to redirect_to(root_path)
      profile = user.reload.candidate_profile
      expect(profile.work_experiences.count).to eq(1)
      expect(profile.educations.count).to eq(1)
    end

    it "discards a blank nested entry left over from the form's spare row" do
      user = create(:user, :candidate)
      sign_in user

      post candidate_profile_path, params: {
        candidate_profile: {
          phone: "555-0100", current_role: "SWE", target_role: "Senior SWE", location: "Bucharest, RO",
          work_experiences_attributes: { "0" => { company: "", title: "", start_date: "" } }
        }
      }

      expect(response).to redirect_to(root_path)
      expect(user.reload.candidate_profile.work_experiences).to be_empty
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

    it "removes a work experience entry when _destroy is submitted" do
      profile = create(:candidate_profile, :with_cv_entries)
      work_experience = profile.work_experiences.first
      sign_in profile.user

      patch candidate_profile_path, params: {
        candidate_profile: {
          work_experiences_attributes: { "0" => { id: work_experience.id, _destroy: "1" } }
        }
      }

      expect(response).to redirect_to(root_path)
      expect(profile.work_experiences.reload).not_to include(work_experience)
    end
  end
end
