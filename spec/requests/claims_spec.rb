require "rails_helper"

RSpec.describe "Claims", type: :request do
  describe "GET /claim/new" do
    it "is accessible without authentication" do
      get new_claim_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /claim" do
    let!(:invited) { create(:user, :pending_invitation, email: "invitee@example.com") }

    it "activates the account, signs the user in, and redirects to the candidate profile form" do
      post claim_path, params: {
        invitation_code: invited.invitation_code,
        name: "Jane Candidate",
        password: "password123",
        password_confirmation: "password123"
      }

      expect(response).to redirect_to(new_candidate_profile_path)

      invited.reload
      expect(invited).not_to be_pending_invitation
      expect(invited.name).to eq("Jane Candidate")

      follow_redirect!
      expect(response.body).to include("Complete your candidate profile")
    end

    it "redirects an interviewer to the interviewer profile form" do
      invited_interviewer = create(:user, :pending_invitation, :interviewer, email: "int@example.com")

      post claim_path, params: {
        invitation_code: invited_interviewer.invitation_code,
        name: "Ivan Interviewer",
        password: "password123",
        password_confirmation: "password123"
      }

      expect(response).to redirect_to(new_interviewer_profile_path)
    end

    it "rejects an invalid code" do
      post claim_path, params: {
        invitation_code: "0000000000000000",
        name: "Jane Candidate",
        password: "password123",
        password_confirmation: "password123"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(invited.reload).to be_pending_invitation
    end

    it "rejects a mismatched password confirmation" do
      post claim_path, params: {
        invitation_code: invited.invitation_code,
        name: "Jane Candidate",
        password: "password123",
        password_confirmation: "somethingelse"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(invited.reload).to be_pending_invitation
    end

    it "rejects a code that was already claimed" do
      invited.claim!(name: "Already Claimed", password: "password123", password_confirmation: "password123")
      code_before = invited.invitation_code

      post claim_path, params: {
        invitation_code: code_before,
        name: "New Name",
        password: "password123",
        password_confirmation: "password123"
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "is rate-limited after repeated attempts from the same IP" do
      11.times do
        post claim_path, params: { invitation_code: "0000000000000000", name: "x", password: "x", password_confirmation: "x" }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
