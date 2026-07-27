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
    years_of_experience = rand(0..10)
    profile = user.create_candidate_profile!(
      phone: Faker::PhoneNumber.phone_number,
      current_role: Faker::Job.title,
      target_role: target_roles.sample,
      years_of_experience: years_of_experience,
      location: "#{Faker::Address.city}, #{Faker::Address.country}",
      bio: Faker::Lorem.paragraph(sentence_count: 2)
    )

    rand(1..2).times do |job_index|
      starts_ago = years_of_experience - (job_index * 2)
      profile.work_experiences.create!(
        company: Faker::Company.name,
        title: Faker::Job.title,
        start_date: [ starts_ago, 1 ].max.years.ago.to_date,
        end_date: job_index.zero? ? nil : (starts_ago - 2).years.ago.to_date,
        description: Faker::Lorem.paragraph(sentence_count: 2)
      )
    end

    profile.educations.create!(
      institution: Faker::University.name,
      degree: Faker::Educator.degree,
      field_of_study: Faker::Educator.subject,
      start_date: (years_of_experience + 6).years.ago.to_date,
      end_date: (years_of_experience + 2).years.ago.to_date
    )

    user
  end

  interview_types = Interview.interview_types.keys

  # One shared template per interview type, so the demo data shows off the
  # question bank and the checklist it produces on an interview, not just an
  # empty "New template" screen.
  question_bank = {
    "technical" => [
      "Explain the difference between a block, a proc, and a lambda.",
      "What causes an N+1 query, and how would you spot one?",
      "Walk through how you'd debug a memory leak in a long-running process.",
      "What's the difference between optimistic and pessimistic locking?"
    ],
    "behavioral" => [
      "Tell me about a time you disagreed with a technical decision.",
      "Describe a project that didn't go as planned. What did you learn?",
      "How do you prioritize when everything feels urgent?",
      "Tell me about a time you had to give difficult feedback."
    ],
    "system_design" => [
      "Design a URL shortener that can handle 10M requests per day.",
      "How would you design a rate limiter?",
      "Walk through the tradeoffs of SQL vs NoSQL for a social feed.",
      "How would you shard a growing multi-tenant database?"
    ]
  }

  templates = interview_types.map do |type|
    template = InterviewTemplate.create!(
      name: "#{type.humanize} interview template",
      interview_type: type,
      description: "Standard #{type.humanize.downcase} interview question set.",
      created_by: interviewers.sample
    )
    question_bank.fetch(type).each { |prompt| template.template_questions.create!(prompt: prompt) }
    template
  end

  100.times do
    scheduled_offset = rand(-60..15)
    scheduled_at = scheduled_offset.days.from_now.change(hour: rand(9..17))
    # Future interviews can only be scheduled; past ones are mostly completed
    # with some cancelled/in-progress, so reporting trends look realistic.
    status = scheduled_offset.positive? ? :scheduled : %i[completed completed completed cancelled in_progress].sample
    type = interview_types.sample
    # Half of past/active interviews start from a template; scheduled ones and
    # the other half stay blank, so the demo shows both paths.
    template = status != :scheduled && rand < 0.5 ? templates.find { |t| t.interview_type == type } : nil

    interview = Interview.create!(
      interviewer: interviewers.sample,
      candidate: candidates.sample,
      title: "#{type.humanize} Interview",
      interview_type: type,
      status: (status == :completed ? :scheduled : status),
      scheduled_at: scheduled_at,
      duration_minutes: [ 30, 45, 60, 90 ].sample,
      interview_template: template
    )

    if template
      interview.interview_questions.each do |question|
        next if rand < 0.3 # leave some untouched, for realism

        question.update!(
          covered: [ true, true, false ].sample,
          notes: rand < 0.6 ? Faker::Lorem.sentence(word_count: 8) : nil,
          answer: rand < 0.7 ? Faker::Lorem.sentence(word_count: 12) : nil
        )
      end
    end

    next unless status == :completed

    # Creating feedback completes the interview itself (Feedback#complete_interview),
    # so there's no separate status write needed here.
    Feedback.create!(
      interview: interview,
      strengths: Faker::Lorem.sentence(word_count: 10),
      improvements: Faker::Lorem.sentence(word_count: 10),
      recommendation: Feedback.recommendations.keys.sample,
      overall_rating: rand(1..5),
      notes: Faker::Lorem.paragraph(sentence_count: 2)
    )
  end

  puts "Seeded #{interviewers.size} interviewers, #{candidates.size} candidates, " \
       "#{Interview.count} interviews (#{Feedback.count} with feedback), " \
       "#{InterviewTemplate.count} interview templates."
end
