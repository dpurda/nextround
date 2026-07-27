FactoryBot.define do
  factory :interview_question do
    interview
    prompt { "Explain the difference between a block, a proc, and a lambda." }
  end
end
