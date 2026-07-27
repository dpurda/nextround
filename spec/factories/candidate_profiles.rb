FactoryBot.define do
  factory :candidate_profile do
    user factory: %i[user candidate]
    phone { "555-0100" }
    current_role { "Software Engineer" }
    target_role { "Senior Software Engineer" }
    years_of_experience { 3 }
    education { "BS Computer Science, MIT" }
    location { "Bucharest, RO" }
    work_experience { "3 years at Acme Corp as a backend engineer" }
    bio { "Motivated engineer preparing for senior interviews." }
  end
end
