FactoryBot.define do
  factory :education do
    candidate_profile
    institution { "MIT" }
    degree { "BS" }
    field_of_study { "Computer Science" }
    start_date { 8.years.ago.to_date }
    end_date { 4.years.ago.to_date }
  end
end
