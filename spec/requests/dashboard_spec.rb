require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    it "redirects to sign in when not authenticated" do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows a welcome message and a profile-incomplete notice linking to the candidate profile form" do
      user = create(:user, :candidate, name: "Jane Candidate")
      sign_in user

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome, Jane Candidate")
      expect(response.body).to include("complete yet")
      expect(response.body).to include(new_candidate_profile_path)
    end

    it "links the profile-incomplete notice to the interviewer profile form for interviewers" do
      sign_in create(:user, :interviewer)

      get root_path

      expect(response.body).to include(new_interviewer_profile_path)
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

    it "shows the invites nav link to admins and interviewers, but not candidates" do
      sign_in create(:user, :admin)
      get root_path
      expect(response.body).to include(">Invites<")

      sign_in create(:user, :interviewer)
      get root_path
      expect(response.body).to include(">Invites<")

      sign_in create(:user, :candidate)
      get root_path
      expect(response.body).not_to include(">Invites<")
    end

    it "shows a 'My profile' nav link for candidates and interviewers, but not admins" do
      sign_in create(:user, :candidate)
      get root_path
      expect(response.body).to include(">My profile<")

      sign_in create(:user, :interviewer)
      get root_path
      expect(response.body).to include(">My profile<")

      sign_in create(:user, :admin)
      get root_path
      expect(response.body).not_to include(">My profile<")
    end

    it "shows the interviews nav link to every role" do
      %i[admin interviewer candidate].each do |role|
        sign_in create(:user, role)
        get root_path
        expect(response.body).to include(">Interviews<")
      end
    end
  end
end
