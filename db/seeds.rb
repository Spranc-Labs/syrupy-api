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
if Rails.env.development?
  puts "Creating demo user..."

  # Check if demo user already exists
  demo_account = Account.find_by(email: "demo@syrupy.com")
  if demo_account.nil?
    # Create account with authentication
    demo_account = Account.create!(
      email: "demo@syrupy.com",
      password: "password123",
      password_confirmation: "password123",
      status: 2 # verified
    )

    # Create user profile
    demo_user = User.create!(
      account_id: demo_account.id,
      first_name: "Demo",
      last_name: "User",
      email: "demo@syrupy.com"
    )
    puts "✓ Created demo user: demo@syrupy.com / password123"
  else
    demo_user = demo_account.user
    puts "✓ Demo user already exists: demo@syrupy.com"
  end

  # Create sample journal entries with emotion analysis
  if demo_user.journal_entries.empty?
    puts "Creating sample journal entries..."
    
    # Entry 1: Positive reflection
    entry1 = demo_user.journal_entries.create!(
      title: "My First Journal Entry",
      content: "Today I'm starting my journaling journey with Syrupy. I'm excited to track my thoughts, moods, and goals over time. This platform will help me practice stoic principles and turn self-reflection into actionable insights."
    )
    entry1.tags << [gratitude_tag, reflection_tag]
    
    # Create emotion analysis for entry1
    emotion_analysis1 = entry1.emotion_label_analyses.create!(
      analysis_model: 'emotion_classifier',
      model_version: '1.0',
      payload: { 'happiness' => 0.8, 'excitement' => 0.7, 'optimism' => 0.6 },
      top_emotion: 'happiness',
      run_ms: 150,
      analyzed_at: Time.current
    )

    journal_analysis1 = entry1.journal_label_analyses.create!(
      analysis_model: 'category_classifier',
      model_version: '1.0',
      payload: { 'category' => 'personal_growth' },
      run_ms: 120,
      analyzed_at: Time.current
    )
    
    entry1.update!(
      emotion_label_analysis: emotion_analysis1,
      journal_label_analysis: journal_analysis1
    )
    
    # Entry 2: Challenging day
    entry2 = demo_user.journal_entries.create!(
      title: "Dealing with Stress",
      content: "Today was particularly challenging at work. Multiple deadlines converging and feeling overwhelmed. However, I'm trying to apply stoic principles - focusing on what I can control and accepting what I cannot. This too shall pass.",
      created_at: 1.day.ago
    )
    entry2.tags << [reflection_tag]
    
    emotion_analysis2 = entry2.emotion_label_analyses.create!(
      analysis_model: 'emotion_classifier',
      model_version: '1.0',
      payload: { 'stress' => 0.7, 'determination' => 0.5, 'acceptance' => 0.4 },
      top_emotion: 'stress',
      run_ms: 180,
      analyzed_at: 1.day.ago
    )

    journal_analysis2 = entry2.journal_label_analyses.create!(
      analysis_model: 'category_classifier',
      model_version: '1.0',
      payload: { 'category' => 'work_stress' },
      run_ms: 140,
      analyzed_at: 1.day.ago
    )
    
    entry2.update!(
      emotion_label_analysis: emotion_analysis2,
      journal_label_analysis: journal_analysis2
    )
    
    # Entry 3: Gratitude focus
    entry3 = demo_user.journal_entries.create!(
      title: "Gratitude Practice",
      content: "Taking time to appreciate the good things in my life. Grateful for my health, supportive family, and the opportunity to grow. Sometimes it's easy to focus on what's missing rather than what's present.",
      created_at: 2.days.ago
    )
    entry3.tags << [gratitude_tag, daily_tag]
    
    emotion_analysis3 = entry3.emotion_label_analyses.create!(
      analysis_model: 'emotion_classifier',
      model_version: '1.0',
      payload: { 'gratitude' => 0.9, 'contentment' => 0.7, 'peace' => 0.6 },
      top_emotion: 'gratitude',
      run_ms: 160,
      analyzed_at: 2.days.ago
    )

    journal_analysis3 = entry3.journal_label_analyses.create!(
      analysis_model: 'category_classifier',
      model_version: '1.0',
      payload: { 'category' => 'gratitude_practice' },
      run_ms: 130,
      analyzed_at: 2.days.ago
    )
    
    entry3.update!(
      emotion_label_analysis: emotion_analysis3,
      journal_label_analysis: journal_analysis3
    )
  end

  # Create emotion logs
  if demo_user.emotion_logs.empty?
    puts "Creating sample emotion logs..."

    emotions_data = [
      { emotion_label: :happy, emoji: '😊', note: 'Great start to the day!', time: Time.current },
      { emotion_label: :content, emoji: '😌', note: 'Feeling peaceful after meditation', time: 3.hours.ago },
      { emotion_label: :grateful, emoji: '🙏', note: 'Thankful for family time', time: 1.day.ago },
      { emotion_label: :anxious, emoji: '😰', note: 'Worried about upcoming presentation', time: 2.days.ago },
      { emotion_label: :excited, emoji: '🤩', note: 'Looking forward to weekend plans', time: 3.days.ago }
    ]

    emotions_data.each do |emotion_data|
      demo_user.emotion_logs.create!(
        emotion_label: emotion_data[:emotion_label],
        emoji: emotion_data[:emoji],
        note: emotion_data[:note],
        captured_at: emotion_data[:time]
      )
    end
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

  # Load bookmarks seed data
  puts "\n" + "="*50
  load Rails.root.join('db', 'seeds', 'bookmarks.rb')
  puts "="*50 + "\n"
end

# Re-enable auditing
Audited.auditing_enabled = true

puts "Seeding completed!" 