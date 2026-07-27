require "rails_helper"

RSpec.describe "User sessions", type: :request do
  describe "POST /users/sign_in" do
    let(:user) { create(:user, :candidate, password: "password123", password_confirmation: "password123") }

    it "signs in with valid credentials and redirects to root" do
      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(root_path)
    end

    it "rejects invalid credentials" do
      post user_session_path, params: { user: { email: user.email, password: "wrongpassword" } }

      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "rejects a pending (unclaimed) invitation, even with a blank password" do
      pending_user = create(:user, :pending_invitation, email: "pending@example.com")

      post user_session_path, params: { user: { email: pending_user.email, password: "" } }

      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "DELETE /users/sign_out" do
    it "signs the user out" do
      user = create(:user, :candidate)
      sign_in user

      delete destroy_user_session_path

      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
