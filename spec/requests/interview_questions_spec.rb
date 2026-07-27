require "rails_helper"

RSpec.describe "InterviewQuestions", type: :request do
  describe "GET /interviews/:interview_id/interview_questions/:id/edit and PATCH" do
    it "lets the owning interviewer mark a question covered and leave notes inline" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)
      frame_id = ActionView::RecordIdentifier.dom_id(question)

      sign_in interview.interviewer
      get edit_interview_interview_question_path(interview, question)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<turbo-frame id="#{frame_id}"))

      patch interview_interview_question_path(interview, question),
        params: { interview_question: { covered: "1", notes: "Solid answer" } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include(%(turbo-stream action="replace" target="#{frame_id}"))
      expect(question.reload.covered?).to be(true)
      expect(question.notes).to eq("Solid answer")
    end

    it "redirects to the interview on a plain html request" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)

      sign_in interview.interviewer
      patch interview_interview_question_path(interview, question), params: { interview_question: { covered: "1" } }

      expect(response).to redirect_to(interview_path(interview))
    end

    it "lets the candidate submit their own answer" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)
      frame_id = ActionView::RecordIdentifier.dom_id(question)

      sign_in interview.candidate
      get edit_interview_interview_question_path(interview, question)
      expect(response).to have_http_status(:ok)

      patch interview_interview_question_path(interview, question),
        params: { interview_question: { answer: "It captures self and binding." } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).to include(%(turbo-stream action="replace" target="#{frame_id}"))
      expect(question.reload.answer).to eq("It captures self and binding.")
    end

    it "scopes writable fields by role even if the other role's params are submitted" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)

      sign_in interview.candidate
      patch interview_interview_question_path(interview, question),
        params: { interview_question: { answer: "my answer", covered: "1", notes: "sneaky" } }
      question.reload
      expect(question.answer).to eq("my answer")
      expect(question.covered?).to be(false)
      expect(question.notes).to be_nil

      sign_in interview.interviewer
      patch interview_interview_question_path(interview, question),
        params: { interview_question: { covered: "1", notes: "Good", answer: "hijacked" } }
      question.reload
      expect(question.covered?).to be(true)
      expect(question.notes).to eq("Good")
      expect(question.answer).to eq("my answer")
    end

    it "is forbidden for an unrelated interviewer" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)

      sign_in create(:user, :interviewer)
      get edit_interview_interview_question_path(interview, question)
      expect(response).to redirect_to(root_path)

      patch interview_interview_question_path(interview, question), params: { interview_question: { covered: "1" } }
      expect(response).to redirect_to(root_path)
      expect(question.reload.covered?).to be(false)
    end

    it "is forbidden for a candidate who is not on the interview" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)

      sign_in create(:user, :candidate)
      get edit_interview_interview_question_path(interview, question)
      expect(response).to redirect_to(root_path)

      patch interview_interview_question_path(interview, question), params: { interview_question: { answer: "nope" } }
      expect(response).to redirect_to(root_path)
      expect(question.reload.answer).to be_nil
    end

    it "allows an admin to edit any interview's question" do
      interview = create(:interview)
      question = create(:interview_question, interview: interview)

      sign_in create(:user, :admin)
      patch interview_interview_question_path(interview, question), params: { interview_question: { covered: "1" } }

      expect(question.reload.covered?).to be(true)
    end
  end
end
