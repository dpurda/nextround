FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    role { :candidate }
    claimed_at { Time.current }
    password { "password123" }
    password_confirmation { "password123" }

    trait :candidate do
      role { :candidate }
    end

    trait :interviewer do
      role { :interviewer }
    end

    trait :admin do
      role { :admin }
    end

    trait :pending_invitation do
      claimed_at { nil }
      name { "" }
      password { nil }
      password_confirmation { nil }
    end
  end
end
