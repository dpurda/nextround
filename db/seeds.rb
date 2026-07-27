# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

admin_email = ENV.fetch("NEXTROUND_ADMIN_EMAIL", "admin@nextround.test")
admin_password = ENV.fetch("NEXTROUND_ADMIN_PASSWORD", "password123")

admin = User.find_or_initialize_by(email: admin_email)
admin.assign_attributes(
  name: "NextRound Admin",
  role: :admin,
  claimed_at: admin.claimed_at || Time.current,
  password: admin_password,
  password_confirmation: admin_password
)
admin.save!

puts "Admin ready: #{admin_email} / #{admin_password}" unless Rails.env.test?

# Demo data: skipped in test (keeps the suite fast) and only generated once
# per fresh database (Faker output isn't deterministic across runs, so this
# guard is what keeps re-running `db:seed` from piling up duplicates).
if !Rails.env.test? && Interview.count.zero?
  tech_skills = [ "Ruby", "Rails", "JavaScript", "React", "System Design", "SQL", "Python", "Algorithms", "DevOps", "Go" ]
  target_roles = [ "Software Engineer", "Senior Software Engineer", "Staff Engineer", "Engineering Manager", "Backend Engineer", "Frontend Engineer" ]
  demo_password = "password123"

  # Admin invites every interviewer; each interviewer in turn invites their
  # own slice of candidates, so the invites list / invited_by lineage reads
  # like a real chain instead of everyone being unrelated.
  interviewers = Array.new(5) do
    user = User.create!(
      email: Faker::Internet.unique.email,
      name: Faker::Name.name,
      role: :interviewer,
      claimed_at: Time.current,
      invited_by: admin,
      password: demo_password,
      password_confirmation: demo_password
    )
    user.create_interviewer_profile!(
      expertise: tech_skills.sample(rand(2..4)).join(", "),
      years_of_experience: rand(2..15),
      company: Faker::Company.name,
      title: Faker::Job.title
    )
    user
  end

  candidates = Array.new(20) do |i|
    user = User.create!(
      email: Faker::Internet.unique.email,
      name: Faker::Name.name,
      role: :candidate,
      claimed_at: Time.current,
      invited_by: interviewers[i % interviewers.size],
      password: demo_password,
      password_confirmation: demo_password
    )
    user.create_candidate_profile!(
      phone: Faker::PhoneNumber.phone_number,
      current_role: Faker::Job.title,
      target_role: target_roles.sample,
      years_of_experience: rand(0..10),
      education: "#{Faker::Educator.degree} - #{Faker::University.name}",
      location: "#{Faker::Address.city}, #{Faker::Address.country}",
      work_experience: Faker::Lorem.paragraph(sentence_count: 2)
    )
    user
  end

  interview_types = Interview.interview_types.keys

  100.times do
    scheduled_offset = rand(-60..15)
    scheduled_at = scheduled_offset.days.from_now.change(hour: rand(9..17))
    # Future interviews can only be scheduled; past ones are mostly completed
    # with some cancelled/in-progress, so reporting trends look realistic.
    status = scheduled_offset.positive? ? :scheduled : %i[completed completed completed cancelled in_progress].sample
    type = interview_types.sample

    interview = Interview.create!(
      interviewer: interviewers.sample,
      candidate: candidates.sample,
      title: "#{type.humanize} Interview",
      interview_type: type,
      status: (status == :completed ? :scheduled : status),
      scheduled_at: scheduled_at,
      duration_minutes: [ 30, 45, 60, 90 ].sample
    )

    next unless status == :completed

    Feedback.create!(
      interview: interview,
      strengths: Faker::Lorem.sentence(word_count: 10),
      improvements: Faker::Lorem.sentence(word_count: 10),
      recommendation: Feedback.recommendations.keys.sample,
      overall_rating: rand(1..5),
      notes: Faker::Lorem.paragraph(sentence_count: 2)
    )
    interview.update!(status: :completed)
  end

  puts "Seeded #{interviewers.size} interviewers, #{candidates.size} candidates, " \
       "#{Interview.count} interviews (#{Feedback.count} with feedback)."
end
