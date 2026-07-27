FactoryBot.define do
  factory :interview do
    interviewer factory: %i[user interviewer]
    candidate factory: %i[user candidate]
    title { "Ruby technical screen" }
    interview_type { :technical }
    status { :scheduled }
    scheduled_at { 1.day.from_now }
    duration_minutes { 60 }
  end
end
