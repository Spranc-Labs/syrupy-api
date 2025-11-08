# frozen_string_literal: true

# Bookmarks seed data
# This file creates sample bookmarks and collections for demo/testing

puts '🔖 Seeding bookmarks and collections...'

# Find first user (or create demo user)
user = User.first

unless user
  puts '⚠️  No users found. Please create a user first.'
  exit
end

puts "📝 Creating collections for user: #{user.email}"

# Create collections (default "Unsorted" should already exist from callback)
collections_data = [
  { name: 'Reading List', icon: '📚', color: '#ef4444', description: 'Articles and blog posts to read' },
  { name: 'Research', icon: '🔬', color: '#3b82f6', description: 'Research papers and documentation' },
  { name: 'Learning', icon: '🎓', color: '#10b981', description: 'Tutorials and courses' },
  { name: 'Inspiration', icon: '✨', color: '#f59e0b', description: 'Design and creative inspiration' },
  { name: 'Tools', icon: '🛠️', color: '#6366f1', description: 'Useful tools and resources' }
]

collections = collections_data.map do |data|
  user.collections.find_or_create_by!(name: data[:name]) do |collection|
    collection.icon = data[:icon]
    collection.color = data[:color]
    collection.description = data[:description]
  end
end

# Get the default "Unsorted" collection
unsorted = user.collections.find_by(is_default: true)

puts "✅ Created #{collections.size} collections"

# Create sample bookmarks with the URLs provided
bookmarks_data = [
  {
    url: 'https://www.reddit.com/r/ClaudeAI/comments/1ojuqhm/10_claude_skills_that_actually_changed_how_i_work/',
    title: '10 Claude Skills That Actually Changed How I Work',
    description: 'A comprehensive guide to Claude skills that improve productivity',
    collection: collections.find { |c| c.name == 'Learning' },
    tags: %w[claude ai productivity],
    status: 'unsorted',
    source: 'manual',
    metadata: {
      domain: 'reddit.com',
      preview: {
        site_name: 'Reddit',
        favicon: 'https://www.redditstatic.com/shreddit/assets/favicon/76x76.png'
      }
    }
  },
  {
    url: 'https://www.reddit.com/r/ClaudeAI/comments/1ok9v3d/i_tested_30_community_claude_skills_for_a_week/',
    title: "I tested 30+ community Claude Skills for a week. Here's what actually works",
    description: 'Complete list of tested Claude Skills with GitHub links',
    collection: collections.find { |c| c.name == 'Learning' },
    tags: %w[claude ai skills testing],
    status: 'read',
    read_at: 2.days.ago,
    source: 'manual',
    metadata: {
      domain: 'reddit.com',
      preview: {
        site_name: 'Reddit',
        favicon: 'https://www.redditstatic.com/shreddit/assets/favicon/76x76.png'
      }
    }
  },
  {
    url: 'https://readwise.io/read',
    title: 'Readwise Reader',
    description: 'Read-it-later app that helps you read more',
    collection: collections.find { |c| c.name == 'Tools' },
    tags: %w[reading productivity tools],
    status: 'favorite',
    source: 'manual',
    metadata: {
      domain: 'readwise.io',
      preview: {
        site_name: 'Readwise',
        image: 'https://readwise.io/static/img/reader-og.png'
      }
    }
  },
  {
    url: 'https://github.com/events/universe/recap#vs-code',
    title: 'GitHub Universe · Recap',
    description: "GitHub's global developer event is back",
    collection: collections.find { |c| c.name == 'Inspiration' },
    tags: %w[github events developer],
    status: 'unsorted',
    source: 'heyho',
    heyho_page_visit_id: 'pv_1761945600498_624',
    metadata: {
      domain: 'github.com',
      preview: {
        image: 'https://images.ctfassets.net/8aevphvgewt8/4zecN9WigxYSqHr7fYJlcl/f633ec5c073996517b73607e72e79022/og-image.jpg',
        favicon: 'https://github.githubassets.com/favicons/favicon.svg',
        description: "GitHub's global developer event is back. Join the world's fair of software.",
        site_name: 'GitHub'
      }
    }
  },
  {
    url: 'https://github.com/donnemartin/system-design-primer?tab=readme-ov-file#system-design-topics-start-here',
    title: 'System Design Primer',
    description: 'Learn how to design large-scale systems. Prep for the system design interview.',
    collection: collections.find { |c| c.name == 'Research' },
    tags: %w[system-design architecture interview],
    status: 'unsorted',
    source: 'heyho',
    heyho_page_visit_id: 'pv_1762009594162_625',
    metadata: {
      domain: 'github.com',
      preview: {
        favicon: 'https://github.githubassets.com/favicons/favicon.svg',
        site_name: 'GitHub'
      }
    }
  },
  {
    url: 'https://www.youtube.com/watch?v=ck0IfiPaQi0&list=PL3MmuxUbc_hIhxl5Ji8t4O6lPAOpHaCLR&index=18',
    title: 'ML Zoomcamp 2.4 - Setting Up The Validation Framework',
    description: 'Learn how to set up validation framework for machine learning projects',
    collection: collections.find { |c| c.name == 'Learning' },
    tags: %w[machine-learning python tutorial],
    status: 'unsorted',
    source: 'heyho',
    heyho_page_visit_id: 'pv_1761945622289_626',
    metadata: {
      domain: 'youtube.com',
      preview: {
        image: 'https://i.ytimg.com/vi/ck0IfiPaQi0/maxresdefault.jpg',
        favicon: 'https://www.youtube.com/s/desktop/ab67e92c/img/favicon_32x32.png',
        description: 'Join the next cohort of the ML Zoomcamp...',
        site_name: 'YouTube'
      }
    }
  },
  {
    url: 'https://www.youtube.com/watch?v=-W9F__D3oY4',
    title: 'CS75 (Summer 2012) Lecture 9 Scalability Harvard Web Development David Malan',
    description: 'David Malan teaching CS75 lecture 9, Scalability',
    collection: collections.find { |c| c.name == 'Learning' },
    tags: %w[scalability web-development harvard lecture],
    status: 'read',
    read_at: 1.day.ago,
    source: 'heyho',
    heyho_page_visit_id: 'pv_1761945637304_627',
    metadata: {
      domain: 'youtube.com',
      preview: {
        image: 'https://i.ytimg.com/vi/-W9F__D3oY4/hqdefault.jpg',
        favicon: 'https://www.youtube.com/s/desktop/3fd9a6f6/img/favicon_32x32.png',
        description: 'David Malan teaching CS75 lecture 9, Scalability',
        site_name: 'YouTube'
      }
    }
  },
  # Additional sample bookmarks for variety
  {
    url: 'https://tailwindcss.com/docs',
    title: 'Tailwind CSS Documentation',
    description: 'A utility-first CSS framework for rapid UI development',
    collection: collections.find { |c| c.name == 'Tools' },
    tags: %w[css tailwind documentation],
    status: 'favorite',
    source: 'manual',
    metadata: {
      domain: 'tailwindcss.com',
      preview: {
        site_name: 'Tailwind CSS'
      }
    }
  },
  {
    url: 'https://ui.shadcn.com/',
    title: 'shadcn/ui - Beautifully designed components',
    description: 'Re-usable components built with Radix UI and Tailwind CSS',
    collection: collections.find { |c| c.name == 'Inspiration' },
    tags: %w[ui react components],
    status: 'unsorted',
    source: 'manual',
    metadata: {
      domain: 'ui.shadcn.com'
    }
  },
  {
    url: 'https://roadmap.sh/frontend',
    title: 'Frontend Developer Roadmap',
    description: 'Step by step guide to becoming a modern frontend developer',
    collection: collections.find { |c| c.name == 'Learning' },
    tags: %w[roadmap frontend career],
    status: 'unsorted',
    source: 'manual',
    metadata: {
      domain: 'roadmap.sh'
    }
  }
]

puts "📚 Creating #{bookmarks_data.size} sample bookmarks..."

bookmarks_data.each do |data|
  # Extract tags from data
  tag_names = data.delete(:tags) || []

  # Create bookmark
  bookmark = user.bookmarks.find_or_create_by!(url: data[:url]) do |b|
    b.title = data[:title]
    b.description = data[:description]
    b.collection = data[:collection] || unsorted
    b.status = data[:status] || 'unsorted'
    b.source = data[:source] || 'manual'
    b.heyho_page_visit_id = data[:heyho_page_visit_id]
    b.metadata = data[:metadata] || {}
    b.read_at = data[:read_at] if data[:read_at]
    b.saved_at = data[:saved_at] || Time.current
  end

  # Add tags
  tag_names.each do |tag_name|
    tag = Tag.find_or_create_by!(name: tag_name, kind: 'user')
    # Use find_or_create on the join table to avoid duplicate key errors
    BookmarkTag.find_or_create_by!(bookmark: bookmark, tag: tag)
  end

  puts "  ✓ #{bookmark.title[0..50]}..."
end

puts ''
puts '✅ Seed completed!'
puts ''
puts '📊 Summary:'
puts "  • Collections: #{user.collections.count}"
puts "  • Bookmarks: #{user.bookmarks.count}"
puts "  • Tags: #{Tag.where(kind: 'user').count}"
puts ''
puts '🔗 Collections breakdown:'
user.collections.each do |collection|
  count = collection.bookmarks.count
  puts "  #{collection.icon} #{collection.name}: #{count} bookmarks"
end
