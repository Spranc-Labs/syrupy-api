# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Disable auditing during seeding to avoid YAML serialization issues
Audited.auditing_enabled = false

# Create default tags
puts "Creating tags..."
gratitude_tag = Tag.find_or_create_by!(name: "gratitude") do |tag|
  tag.color = "#10b981"
end

reflection_tag = Tag.find_or_create_by!(name: "reflection") do |tag|
  tag.color = "#6366f1"
end

goals_tag = Tag.find_or_create_by!(name: "goals") do |tag|
  tag.color = "#f59e0b"
end

daily_tag = Tag.find_or_create_by!(name: "daily") do |tag|
  tag.color = "#ef4444"
end

puts "Created #{Tag.count} tags"

# Create a demo user (only in development) 
# TODO: Re-enable demo account creation when authentication is fixed
if Rails.env.development?
  puts "Creating demo user..."
  
  # For now, create a user without an account since Account model has issues
  demo_user = User.find_by(email: "demo@syrupy.com") 
  if demo_user.nil?
    demo_user = User.create!(
      first_name: "Demo",
      last_name: "User",
      email: "demo@syrupy.com"
      # account: nil # TODO: Fix this when authentication is working
    )
  end

  # Create sample journal entry
  if demo_user.journal_entries.empty?
    puts "Creating sample journal entry..."
    entry = demo_user.journal_entries.create!(
      title: "My First Journal Entry",
      content: "Today I'm starting my journaling journey with Syrupy. I'm excited to track my thoughts, moods, and goals over time. This platform will help me practice stoic principles and turn self-reflection into actionable insights.",
      mood_rating: 8
    )
    entry.tags << [gratitude_tag, reflection_tag]
  end

  # Create sample goals
  if demo_user.goals.empty?
    puts "Creating sample goals..."
    demo_user.goals.create!([
      {
        title: "Daily Journaling",
        description: "Write in my journal every day for 30 days",
        status: "active",
        priority: "high",
        target_date: Date.current + 30.days
      },
      {
        title: "Read Stoic Philosophy",
        description: "Read 'Meditations' by Marcus Aurelius",
        status: "active", 
        priority: "medium",
        target_date: Date.current + 60.days
      }
    ])
  end

  # Create sample habits
  if demo_user.habits.empty?
    puts "Creating sample habits..."
    meditation_habit = demo_user.habits.create!(
      name: "Morning Meditation",
      description: "10 minutes of mindfulness meditation",
      frequency: "daily",
      active: true
    )

    exercise_habit = demo_user.habits.create!(
      name: "Exercise",
      description: "30 minutes of physical activity",
      frequency: "daily", 
      active: true
    )

    # Create some habit logs
    puts "Creating sample habit logs..."
    5.times do |i|
      date = i.days.ago.to_date
      demo_user.habit_logs.create!(
        habit: meditation_habit,
        logged_date: date,
        completed: true,
        notes: "Completed morning meditation session"
      )
      
      if i.even?  # Every other day for exercise
        demo_user.habit_logs.create!(
          habit: exercise_habit,
          logged_date: date,
          completed: true,
          notes: "30-minute workout completed"
        )
      end
    end
  end

  # Create sample mood logs
  if demo_user.mood_logs.empty?
    puts "Creating sample mood logs..."
    7.times do |i|
      demo_user.mood_logs.create!(
        rating: rand(6..9),
        notes: "Daily mood check-in",
        logged_at: i.days.ago
      )
    end
  end

  puts "Demo data created successfully!"
  puts "Demo user: #{demo_user.email}"
end

# Re-enable auditing
Audited.auditing_enabled = true

puts "Seeding completed!" 