require "rails_helper"

RSpec.describe "Interviews", type: :request do
  describe "GET /interviews" do
    it "shows an admin every interview" do
      mine = create(:interview)
      other = create(:interview)

      sign_in create(:user, :admin)
      get interviews_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(mine.title)
      expect(response.body).to include(other.title)
    end

    it "scopes to only the interviewer's own interviews" do
      mine = create(:interview, title: "Mine")
      other = create(:interview, title: "Not mine")

      sign_in mine.interviewer
      get interviews_path

      expect(response.body).to include(mine.title)
      expect(response.body).not_to include(other.title)
    end

    it "scopes to only the candidate's own interviews" do
      mine = create(:interview, title: "Mine")
      other = create(:interview, title: "Not mine")

      sign_in mine.candidate
      get interviews_path

      expect(response.body).to include(mine.title)
      expect(response.body).not_to include(other.title)
    end
  end

  describe "GET /interviews/new" do
    it "is accessible to interviewers and admins" do
      sign_in create(:user, :interviewer)
      get new_interview_path
      expect(response).to have_http_status(:ok)

      sign_in create(:user, :admin)
      get new_interview_path
      expect(response).to have_http_status(:ok)
    end

    it "is forbidden for candidates" do
      sign_in create(:user, :candidate)
      get new_interview_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /interviews" do
    it "forces the interviewer to themselves regardless of submitted interviewer_id" do
      interviewer = create(:user, :interviewer)
      other_interviewer = create(:user, :interviewer)
      candidate = create(:user, :candidate)

      sign_in interviewer

      post interviews_path, params: {
        interview: {
          title: "Ruby screen", interview_type: "technical", candidate_id: candidate.id,
          interviewer_id: other_interviewer.id, scheduled_at: 1.day.from_now
        }
      }

      created = Interview.find_by(title: "Ruby screen")
      expect(created.interviewer_id).to eq(interviewer.id)
      expect(response).to redirect_to(interview_path(created))
    end

    it "lets an admin pick both interviewer and candidate" do
      interviewer = create(:user, :interviewer)
      candidate = create(:user, :candidate)
      sign_in create(:user, :admin)

      post interviews_path, params: {
        interview: {
          title: "System design", interview_type: "system_design", candidate_id: candidate.id,
          interviewer_id: interviewer.id, scheduled_at: 1.day.from_now
        }
      }

      created = Interview.find_by(title: "System design")
      expect(created.interviewer_id).to eq(interviewer.id)
      expect(created.candidate_id).to eq(candidate.id)
    end

    it "is forbidden for candidates" do
      sign_in create(:user, :candidate)

      expect do
        post interviews_path, params: { interview: { title: "x" } }
      end.not_to change(Interview, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /interviews/:id" do
    it "is visible to the owning interviewer, the candidate, and an admin" do
      interview = create(:interview)

      sign_in interview.interviewer
      get interview_path(interview)
      expect(response).to have_http_status(:ok)

      sign_in interview.candidate
      get interview_path(interview)
      expect(response).to have_http_status(:ok)

      sign_in create(:user, :admin)
      get interview_path(interview)
      expect(response).to have_http_status(:ok)
    end

    it "is forbidden for an unrelated interviewer or candidate" do
      interview = create(:interview)

      sign_in create(:user, :interviewer)
      get interview_path(interview)
      expect(response).to redirect_to(root_path)

      sign_in create(:user, :candidate)
      get interview_path(interview)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /interviews/:id/edit and PATCH" do
    it "lets the owning interviewer update it" do
      interview = create(:interview, title: "Old title")
      sign_in interview.interviewer

      get edit_interview_path(interview)
      expect(response).to have_http_status(:ok)

      patch interview_path(interview), params: { interview: { title: "New title" } }
      expect(response).to redirect_to(interview_path(interview))
      expect(interview.reload.title).to eq("New title")
    end

    it "is forbidden for the candidate on the interview" do
      interview = create(:interview)
      sign_in interview.candidate

      patch interview_path(interview), params: { interview: { title: "Hijacked" } }

      expect(response).to redirect_to(root_path)
      expect(interview.reload.title).not_to eq("Hijacked")
    end

    it "blocks marking completed without feedback" do
      interview = create(:interview, status: :scheduled)
      sign_in interview.interviewer

      patch interview_path(interview), params: { interview: { status: "completed" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(interview.reload.status).to eq("scheduled")
    end

    it "allows marking completed once feedback exists" do
      interview = create(:interview, status: :scheduled)
      create(:feedback, interview: interview)
      sign_in interview.interviewer

      patch interview_path(interview), params: { interview: { status: "completed" } }

      expect(response).to redirect_to(interview_path(interview))
      expect(interview.reload.status).to eq("completed")
    end
  end
end
