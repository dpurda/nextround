require "rails_helper"

RSpec.describe "InterviewTemplates", type: :request do
  describe "GET /interview_templates" do
    it "is visible to interviewers and admins" do
      create(:interview_template, name: "Ruby screen")
      sign_in create(:user, :interviewer)

      get interview_templates_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ruby screen")
    end

    it "is forbidden for candidates" do
      sign_in create(:user, :candidate)
      get interview_templates_path
      expect(response).to redirect_to(root_path)
    end

    it "searches by name or description" do
      match = create(:interview_template, name: "Ruby backend screen")
      no_match = create(:interview_template, name: "System design round")

      sign_in create(:user, :admin)
      get interview_templates_path, params: { q: { name_or_description_cont: "Ruby" } }

      expect(response.body).to include(match.name)
      expect(response.body).not_to include(no_match.name)
    end

    it "filters by interview_type" do
      technical = create(:interview_template, name: "Technical one", interview_type: :technical)
      behavioral = create(:interview_template, name: "Behavioral one", interview_type: :behavioral)

      sign_in create(:user, :admin)
      get interview_templates_path, params: { q: { interview_type_eq: InterviewTemplate.interview_types[:behavioral] } }

      expect(response.body).to include(behavioral.name)
      expect(response.body).not_to include(technical.name)
    end
  end

  describe "POST /interview_templates" do
    it "creates a template with nested questions, owned by the current interviewer" do
      interviewer = create(:user, :interviewer)
      sign_in interviewer

      post interview_templates_path, params: {
        interview_template: {
          name: "Ruby technical screen", interview_type: "technical", description: "Standard screen.",
          template_questions_attributes: {
            "0" => { prompt: "Explain block vs proc vs lambda" },
            "1" => { prompt: "" }
          }
        }
      }

      template = InterviewTemplate.find_by(name: "Ruby technical screen")
      expect(response).to redirect_to(interview_template_path(template))
      expect(template.created_by).to eq(interviewer)
      expect(template.template_questions.count).to eq(1) # blank row rejected
    end

    it "is forbidden for candidates" do
      sign_in create(:user, :candidate)

      expect do
        post interview_templates_path, params: { interview_template: { name: "x" } }
      end.not_to change(InterviewTemplate, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /interview_templates/:id/edit and PATCH" do
    it "lets the creator update it" do
      template = create(:interview_template, name: "Old name")
      sign_in template.created_by

      get edit_interview_template_path(template)
      expect(response).to have_http_status(:ok)

      patch interview_template_path(template), params: { interview_template: { name: "New name" } }
      expect(response).to redirect_to(interview_template_path(template))
      expect(template.reload.name).to eq("New name")
    end

    it "is forbidden for a different interviewer" do
      template = create(:interview_template, name: "Original")
      sign_in create(:user, :interviewer)

      get edit_interview_template_path(template)
      expect(response).to redirect_to(root_path)

      patch interview_template_path(template), params: { interview_template: { name: "Hijacked" } }
      expect(response).to redirect_to(root_path)
      expect(template.reload.name).to eq("Original")
    end

    it "is allowed for an admin regardless of creator" do
      template = create(:interview_template, name: "Original")
      sign_in create(:user, :admin)

      patch interview_template_path(template), params: { interview_template: { name: "Updated by admin" } }
      expect(template.reload.name).to eq("Updated by admin")
    end
  end

  describe "DELETE /interview_templates/:id" do
    it "lets the creator delete it, nullifying it on interviews that used it" do
      template = create(:interview_template)
      interview = create(:interview, interview_template: template)
      sign_in template.created_by

      delete interview_template_path(template)

      expect(response).to redirect_to(interview_templates_path)
      expect(InterviewTemplate.exists?(template.id)).to be(false)
      expect(interview.reload.interview_template_id).to be_nil
    end

    it "is forbidden for a non-owning interviewer" do
      template = create(:interview_template)
      sign_in create(:user, :interviewer)

      delete interview_template_path(template)

      expect(response).to redirect_to(root_path)
      expect(InterviewTemplate.exists?(template.id)).to be(true)
    end
  end
end
