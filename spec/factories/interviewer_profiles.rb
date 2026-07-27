FactoryBot.define do
  factory :interviewer_profile do
    user factory: %i[user interviewer]
    expertise { "Ruby, System Design" }
    years_of_experience { 8 }
    company { "Acme Corp" }
    title { "Staff Engineer" }
    bio { "Enjoys running technical interviews." }
  end
end
