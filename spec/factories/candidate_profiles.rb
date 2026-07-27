FactoryBot.define do
  factory :candidate_profile do
    user factory: %i[user candidate]
    phone { "555-0100" }
    current_role { "Software Engineer" }
    target_role { "Senior Software Engineer" }
    years_of_experience { 3 }
    location { "Bucharest, RO" }
    bio { "Motivated engineer preparing for senior interviews." }

    trait :with_cv_entries do
      after(:create) do |profile|
        profile.work_experiences.create!(
          company: "Acme Corp", title: "Backend Engineer",
          start_date: 3.years.ago.to_date, end_date: nil,
          description: "Building backend services."
        )
        profile.educations.create!(
          institution: "MIT", degree: "BS", field_of_study: "Computer Science",
          start_date: 8.years.ago.to_date, end_date: 4.years.ago.to_date
        )
      end
    end
  end
end
