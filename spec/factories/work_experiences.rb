FactoryBot.define do
  factory :work_experience do
    candidate_profile
    company { "Acme Corp" }
    title { "Backend Engineer" }
    start_date { 3.years.ago.to_date }
    end_date { nil }
    description { "Building backend services." }
  end
end
