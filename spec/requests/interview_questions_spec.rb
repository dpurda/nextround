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

    it "locks the candidate out of a question once they've already answered it, but leaves other questions open" do
      interview = create(:interview, status: :scheduled)
      answered = interview.interview_questions.create!(prompt: "Q1")
      unanswered = interview.interview_questions.create!(prompt: "Q2")

      sign_in interview.candidate
      patch interview_interview_question_path(interview, answered), params: { interview_question: { answer: "first answer" } }
      expect(interview.reload.status).to eq("in_progress")

      get edit_interview_interview_question_path(interview, answered)
      expect(response).to redirect_to(root_path)

      patch interview_interview_question_path(interview, answered), params: { interview_question: { answer: "trying again" } }
      expect(response).to redirect_to(root_path)
      expect(answered.reload.answer).to eq("first answer")

      get interview_path(interview)
      answered_frame = ActionView::RecordIdentifier.dom_id(answered)
      unanswered_frame = ActionView::RecordIdentifier.dom_id(unanswered)
      answered_html = response.body[/<turbo-frame id="#{answered_frame}".*?<\/turbo-frame>/m]
      unanswered_html = response.body[/<turbo-frame id="#{unanswered_frame}".*?<\/turbo-frame>/m]
      expect(answered_html).not_to include("Answer question")
      expect(unanswered_html).to include("Answer question")

      get edit_interview_interview_question_path(interview, unanswered)
      expect(response).to have_http_status(:ok)
    end

    it "never lets the interviewer or admin write the answer field, even after the interview has started" do
      interview = create(:interview, status: :in_progress)
      question = interview.interview_questions.create!(prompt: "Q")

      sign_in interview.interviewer
      patch interview_interview_question_path(interview, question), params: { interview_question: { answer: "hijacked", covered: "1" } }
      expect(question.reload.answer).to be_nil
      expect(question.covered?).to be(true)

      sign_in create(:user, :admin)
      patch interview_interview_question_path(interview, question), params: { interview_question: { answer: "hijacked again" } }
      expect(question.reload.answer).to be_nil
    end
  end
end
