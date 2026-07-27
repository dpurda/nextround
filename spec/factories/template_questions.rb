FactoryBot.define do
  factory :template_question do
    interview_template
    prompt { "Explain the difference between a block, a proc, and a lambda." }
  end
end
