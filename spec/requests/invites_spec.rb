require "rails_helper"

RSpec.describe "Invites", type: :request do
  describe "GET /invites" do
    it "shows an admin every invited user" do
      interviewer = create(:user, :interviewer)
      candidate_a = create(:user, :pending_invitation, email: "a@example.com", invited_by: interviewer)
      candidate_b = create(:user, :pending_invitation, email: "b@example.com", invited_by: create(:user, :admin))

      sign_in create(:user, :admin)
      get invites_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(candidate_a.email)
      expect(response.body).to include(candidate_b.email)
    end

    it "shows an interviewer only the invites they created" do
      interviewer = create(:user, :interviewer)
      mine = create(:user, :pending_invitation, email: "mine@example.com", invited_by: interviewer)
      not_mine = create(:user, :pending_invitation, email: "notmine@example.com", invited_by: create(:user, :interviewer))

      sign_in interviewer
      get invites_path

      expect(response.body).to include(mine.email)
      expect(response.body).not_to include(not_mine.email)
    end

    it "is forbidden for candidates" do
      sign_in create(:user, :candidate)
      get invites_path
      expect(response).to redirect_to(root_path)
    end

    it "searches by email or name" do
      admin = create(:user, :admin)
      match = create(:user, :pending_invitation, email: "zephyr@example.com", invited_by: admin)
      no_match = create(:user, :pending_invitation, email: "other@example.com", invited_by: admin)

      sign_in admin
      get invites_path, params: { q: { email_or_name_cont: "zephyr" } }

      expect(response.body).to include(match.email)
      expect(response.body).not_to include(no_match.email)
    end

    it "filters by role" do
      admin = create(:user, :admin)
      candidate = create(:user, :pending_invitation, email: "cand@example.com", invited_by: admin)
      interviewer = create(:user, :pending_invitation, :interviewer, email: "int@example.com", invited_by: admin)

      sign_in admin
      # Ransack casts _eq for integer columns with .to_i rather than translating Rails enum
      # string labels — the real form submits the enum's integer value, so the test does too.
      get invites_path, params: { q: { role_eq: User.roles[:interviewer] } }

      expect(response.body).to include(interviewer.email)
      expect(response.body).not_to include(candidate.email)
    end

    it "filters by claimed status" do
      admin = create(:user, :admin)
      pending = create(:user, :pending_invitation, email: "pending@example.com", invited_by: admin)
      claimed = create(:user, :candidate, email: "claimed@example.com", invited_by: admin)

      sign_in admin
      get invites_path, params: { q: { claimed_at_null: "true" } }

      expect(response.body).to include(pending.email)
      expect(response.body).not_to include(claimed.email)
    end

    it "paginates results" do
      admin = create(:user, :admin)
      17.times { |i| create(:user, :pending_invitation, email: "paginated#{i}@example.com", invited_by: admin) }

      sign_in admin
      get invites_path

      expect(response.body).to include("series-nav")
    end
  end

  describe "GET /invites/new" do
    it "is accessible to interviewers" do
      sign_in create(:user, :interviewer)
      get new_invite_path
      expect(response).to have_http_status(:ok)
    end

    it "is accessible to admins" do
      sign_in create(:user, :admin)
      get new_invite_path
      expect(response).to have_http_status(:ok)
    end

    it "is forbidden for candidates" do
      sign_in create(:user, :candidate)
      get new_invite_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /invites" do
    it "lets an interviewer invite a candidate" do
      sign_in create(:user, :interviewer)

      expect do
        post invites_path, params: { user: { email: "newcand@example.com", role: "candidate" } }
      end.to change(User, :count).by(1)

      invited = User.find_by(email: "newcand@example.com")
      expect(invited).to be_pending_invitation
      expect(invited.invitation_code).to be_present
      expect(response).to redirect_to(invite_path(invited))
    end

    it "does not let an interviewer invite another interviewer" do
      sign_in create(:user, :interviewer)

      expect do
        post invites_path, params: { user: { email: "newint@example.com", role: "interviewer" } }
      end.not_to change(User, :count)

      expect(response).to redirect_to(root_path)
    end

    it "does not let an interviewer escalate an invite to admin" do
      sign_in create(:user, :interviewer)

      expect do
        post invites_path, params: { user: { email: "sneaky@example.com", role: "admin" } }
      end.not_to change(User, :count)

      expect(response).to redirect_to(root_path)
    end

    it "lets an admin invite an interviewer" do
      sign_in create(:user, :admin)

      expect do
        post invites_path, params: { user: { email: "newint@example.com", role: "interviewer" } }
      end.to change(User, :count).by(1)
    end

    it "is forbidden for candidates" do
      sign_in create(:user, :candidate)

      expect do
        post invites_path, params: { user: { email: "x@example.com", role: "candidate" } }
      end.not_to change(User, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /invites/:id" do
    it "shows the code to the inviter" do
      interviewer = create(:user, :interviewer)
      invited = create(:user, :pending_invitation, email: "cand@example.com", invited_by: interviewer)

      sign_in interviewer
      get invite_path(invited)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(invited.invitation_code)
    end

    it "is forbidden for a different interviewer" do
      interviewer = create(:user, :interviewer)
      other = create(:user, :interviewer)
      invited = create(:user, :pending_invitation, email: "cand@example.com", invited_by: interviewer)

      sign_in other
      get invite_path(invited)

      expect(response).to redirect_to(root_path)
    end

    it "shows the completed profile once a candidate invite has been claimed" do
      interviewer = create(:user, :interviewer)
      profile = create(:candidate_profile, current_role: "SWE", location: "Bucharest, RO")
      profile.user.update!(invited_by: interviewer)

      sign_in interviewer
      get invite_path(profile.user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SWE")
      expect(response.body).to include("Bucharest, RO")
      expect(response.body).not_to include("Invitation created")
    end

    it "shows a not-yet-completed note when claimed but no profile exists" do
      interviewer = create(:user, :interviewer)
      claimed = create(:user, :candidate, invited_by: interviewer)

      sign_in interviewer
      get invite_path(claimed)

      expect(response.body).to include("haven't completed their profile")
    end
  end
end
