require "rails_helper"

RSpec.describe TemplateQuestion, type: :model do
  it "has a valid factory" do
    expect(build(:template_question)).to be_valid
  end

  it "requires a prompt" do
    question = build(:template_question, prompt: nil)
    expect(question).not_to be_valid
    expect(question.errors[:prompt]).to be_present
  end
end
