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

    it "searches by title across the free-text query" do
      match = create(:interview, title: "Ruby backend screen")
      no_match = create(:interview, title: "System design round")

      sign_in create(:user, :admin)
      get interviews_path, params: { q: { title_or_interviewer_name_or_interviewer_email_or_candidate_name_or_candidate_email_cont: "Ruby" } }

      expect(response.body).to include(match.title)
      expect(response.body).not_to include(no_match.title)
    end

    it "searches by candidate name" do
      match = create(:interview, title: "Match me")
      match.candidate.update!(name: "Zed Zephyr")
      no_match = create(:interview, title: "Skip me")

      sign_in create(:user, :admin)
      get interviews_path, params: { q: { title_or_interviewer_name_or_interviewer_email_or_candidate_name_or_candidate_email_cont: "Zephyr" } }

      expect(response.body).to include(match.title)
      expect(response.body).not_to include(no_match.title)
    end

    it "filters by status" do
      scheduled = create(:interview, title: "Scheduled one", status: :scheduled)
      cancelled = create(:interview, title: "Cancelled one", status: :cancelled)

      sign_in create(:user, :admin)
      # Ransack casts _eq for integer columns with .to_i rather than translating Rails enum
      # string labels — the real form submits the enum's integer value, so the test does too.
      get interviews_path, params: { q: { status_eq: Interview.statuses[:cancelled] } }

      expect(response.body).to include(cancelled.title)
      expect(response.body).not_to include(scheduled.title)
    end

    it "filters by feedback recommendation" do
      interview = create(:interview, title: "Hire candidate")
      create(:feedback, interview: interview, recommendation: :hire)
      other = create(:interview, title: "No feedback")

      sign_in create(:user, :admin)
      # Enum integer value, not the string label — see the "filters by status" test above for why.
      get interviews_path, params: { q: { feedback_recommendation_eq: Feedback.recommendations[:hire] } }

      expect(response.body).to include(interview.title)
      expect(response.body).not_to include(other.title)
    end

    it "paginates results" do
      admin = create(:user, :admin)
      17.times { |i| create(:interview, title: "Paginated interview #{i}") }

      sign_in admin
      get interviews_path

      expect(response.body).to include("series-nav")

      get interviews_path, params: { page: 2 }
      expect(response).to have_http_status(:ok)
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

    it "preselects the template passed via query param" do
      template = create(:interview_template)
      sign_in create(:user, :interviewer)

      get new_interview_path(interview_template_id: template.id)

      expect(response.body).to include(%(<option selected="selected" value="#{template.id}">#{template.name}</option>))
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

    it "copies the selected template's questions onto the new interview" do
      template = create(:interview_template)
      create(:template_question, interview_template: template, prompt: "Explain block vs proc vs lambda")
      candidate = create(:user, :candidate)
      sign_in create(:user, :interviewer)

      post interviews_path, params: {
        interview: {
          title: "Ruby screen", interview_type: "technical", candidate_id: candidate.id,
          interview_template_id: template.id, scheduled_at: 1.day.from_now
        }
      }

      created = Interview.find_by(title: "Ruby screen")
      expect(created.interview_questions.pluck(:prompt)).to contain_exactly("Explain block vs proc vs lambda")
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

    it "responds with turbo_stream updates for both the card and the flash when requested" do
      interview = create(:interview, duration_minutes: 30)
      sign_in interview.interviewer
      frame_id = ActionView::RecordIdentifier.dom_id(interview)

      patch interview_path(interview),
        params: { interview: { duration_minutes: 90 } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include(%(turbo-stream action="replace" target="#{frame_id}"))
      expect(response.body).to include(%(turbo-stream action="replace" target="flash"))
      expect(response.body).to include("Interview updated.")
      expect(response.body).to include("90 minutes")
    end

    it "wraps both the show page details and the edit form in the same turbo frame" do
      interview = create(:interview)
      sign_in interview.interviewer

      frame_id = ActionView::RecordIdentifier.dom_id(interview)

      get interview_path(interview)
      expect(response.body).to include(%(<turbo-frame id="#{frame_id}"))

      get edit_interview_path(interview)
      expect(response.body).to include(%(<turbo-frame id="#{frame_id}"))
    end

    it "re-renders the edit form inline (same frame) when validation fails" do
      interview = create(:interview)
      sign_in interview.interviewer
      frame_id = ActionView::RecordIdentifier.dom_id(interview)

      patch interview_path(interview), params: { interview: { title: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(%(<turbo-frame id="#{frame_id}"))
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

  describe "PATCH /interviews/:id/update_status" do
    it "lets the owning interviewer change the status from the index page dropdown" do
      interview = create(:interview, status: :scheduled)
      sign_in interview.interviewer

      patch update_status_interview_path(interview),
        params: { interview: { status: "in_progress" } },
        headers: { "HTTP_REFERER" => interviews_path }

      expect(response).to redirect_to(interviews_path)
      expect(interview.reload.status).to eq("in_progress")
    end

    it "redirects back to the show page when triggered from there" do
      interview = create(:interview, status: :scheduled)
      sign_in interview.interviewer

      patch update_status_interview_path(interview),
        params: { interview: { status: "in_progress" } },
        headers: { "HTTP_REFERER" => interview_path(interview) }

      expect(response).to redirect_to(interview_path(interview))
    end

    it "is forbidden for the candidate on the interview" do
      interview = create(:interview, status: :scheduled)
      sign_in interview.candidate

      patch update_status_interview_path(interview), params: { interview: { status: "in_progress" } }

      expect(response).to redirect_to(root_path)
      expect(interview.reload.status).to eq("scheduled")
    end

    it "blocks marking completed without feedback and shows an alert" do
      interview = create(:interview, status: :scheduled)
      sign_in interview.interviewer

      patch update_status_interview_path(interview),
        params: { interview: { status: "completed" } },
        headers: { "HTTP_REFERER" => interviews_path }

      expect(response).to redirect_to(interviews_path)
      follow_redirect!
      expect(response.body).to include("cannot be completed without feedback")
      expect(interview.reload.status).to eq("scheduled")
    end
  end
end
