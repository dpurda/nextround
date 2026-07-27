FactoryBot.define do
  factory :feedback do
    interview
    strengths { "Strong problem solving and clear communication." }
    improvements { "Could improve on testing edge cases." }
    recommendation { :hire }
    overall_rating { 4 }
    notes { "Solid candidate overall." }
  end
end
