require "rails_helper"

RSpec.describe "Feedbacks", type: :request do
  describe "GET /interviews/:interview_id/feedback/new" do
    it "is accessible to the owning interviewer" do
      interview = create(:interview)
      sign_in interview.interviewer

      get new_interview_feedback_path(interview)

      expect(response).to have_http_status(:ok)
    end

    it "is forbidden for the candidate on the interview" do
      interview = create(:interview)
      sign_in interview.candidate

      get new_interview_feedback_path(interview)

      expect(response).to redirect_to(root_path)
    end

    it "is forbidden for an unrelated interviewer" do
      interview = create(:interview)
      sign_in create(:user, :interviewer)

      get new_interview_feedback_path(interview)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /interviews/:interview_id/feedback" do
    it "creates feedback and lets the interview be completed afterward" do
      interview = create(:interview, status: :scheduled)
      sign_in interview.interviewer

      post interview_feedback_path(interview), params: {
        feedback: {
          strengths: "Great communication", improvements: "More testing depth",
          recommendation: "hire", overall_rating: 4
        }
      }

      expect(response).to redirect_to(interview_path(interview))
      expect(interview.reload.feedback).to be_present

      patch interview_path(interview), params: { interview: { status: "completed" } }
      expect(interview.reload.status).to eq("completed")
    end

    it "re-renders with errors when required fields are missing" do
      interview = create(:interview)
      sign_in interview.interviewer

      post interview_feedback_path(interview), params: { feedback: { strengths: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "is forbidden for an admin-unrelated interviewer" do
      interview = create(:interview)
      sign_in create(:user, :interviewer)

      expect do
        post interview_feedback_path(interview), params: {
          feedback: { strengths: "x", improvements: "y", recommendation: "hire", overall_rating: 3 }
        }
      end.not_to change(Feedback, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /interviews/:interview_id/feedback/edit and PATCH" do
    it "lets the owning interviewer update existing feedback" do
      interview = create(:interview)
      feedback = create(:feedback, interview: interview, strengths: "Old")
      sign_in interview.interviewer

      get edit_interview_feedback_path(interview)
      expect(response).to have_http_status(:ok)

      patch interview_feedback_path(interview), params: { feedback: { strengths: "New" } }
      expect(response).to redirect_to(interview_path(interview))
      expect(feedback.reload.strengths).to eq("New")
    end

    it "is forbidden for the candidate on the interview" do
      interview = create(:interview)
      create(:feedback, interview: interview)
      sign_in interview.candidate

      patch interview_feedback_path(interview), params: { feedback: { strengths: "Hijacked" } }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "interview show page" do
    it "shows an 'Add feedback' link to the owning interviewer when none exists yet" do
      interview = create(:interview)
      sign_in interview.interviewer

      get interview_path(interview)

      expect(response.body).to include("Add feedback")
      expect(response.body).to include("No feedback yet")
    end

    it "shows the feedback details and an edit link once feedback exists" do
      interview = create(:interview)
      create(:feedback, interview: interview, strengths: "Great communication")
      sign_in interview.interviewer

      get interview_path(interview)

      expect(response.body).to include("Great communication")
      expect(response.body).to include("Edit feedback")
    end

    it "shows feedback to the candidate read-only, without an edit link" do
      interview = create(:interview)
      create(:feedback, interview: interview, strengths: "Great communication")
      sign_in interview.candidate

      get interview_path(interview)

      expect(response.body).to include("Great communication")
      expect(response.body).not_to include("Edit feedback")
      expect(response.body).not_to include("Add feedback")
    end
  end
end
