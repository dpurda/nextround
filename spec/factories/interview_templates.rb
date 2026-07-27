FactoryBot.define do
  factory :interview_template do
    created_by factory: %i[user interviewer]
    name { "Ruby technical screen" }
    interview_type { :technical }
    description { "Standard technical screen for backend candidates." }
  end
end
