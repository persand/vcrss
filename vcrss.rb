require 'digest'
require 'rss'
require 'time'
require 'yaml'

# Create necessary dirs unless they already exists
Dir.mkdir('downloads') unless File.exists?('downloads')
Dir.mkdir('log') unless File.exists?('log')

# Load YML config file
CONFIG = YAML.load_file('config.yml')

# Correct config.yml?
if !CONFIG['feeds']
  puts 'Invalid config file. Please see README.md for an example.'
  exit
end

# Loop feeds
CONFIG["feeds"].each_with_index do |feed, i|

  # Create unique ID for each feed based on the URL and the number in the loop
  feed_md5 = Digest::MD5.new
  feed_md5.update "#{feed['url']}"
  feed_md5.hexdigest

  # Create log file?
  if !File.file?("log/feed-#{feed_md5}.log")
    File.new("log/feed-#{feed_md5}.log", 'w+')
    data = {'log_setup' => Time.now}
    File.open("log/feed-#{feed_md5}.log", 'w') {|f| f.write(data.to_yaml) }
  end

  # Load log file
  log = YAML.load_file("log/feed-#{feed_md5}.log")

  # Load last downloaded pub date for feed
  if !log["#{feed_md5}_date"]
    log_date = 0
  else
    log_date = log["#{feed_md5}_date"].to_i
  end

  # Load last downloaded link for feed
  if !log["#{feed_md5}_link"]
    log_link = ''
  else
    log_link = log["#{feed_md5}_link"]
  end

  # Read feed
  rss = RSS::Parser.parse(feed['url'], false)

  # Reverse loop to make sure that newest item comes last
  rss.items.reverse_each do |item|
    download = true

    # Check feed type and make the correct values are set
    if rss.feed_type == 'rss'
      item_title = item.title
      item_date = item.pubDate.to_time.to_i
      item_link = item.link
    elsif rss.feed_type == 'atom'
      item_title = item.title.content
      item_date = item.published.content.to_time.to_i
      item_link = item.link.href
    end

    # Are there filters? If so check if the item passes them.
    if feed['filters']
      download = false

      feed['filters'].each do |filter|
        if item_title.include? "#{filter}"
          download = true
        end
      end

      next if !download
    end

    # Is the item the older than the log date? If so skip the item.
    if item_date <= log_date
      next
    end

    # Time to download?
    if download
      puts "Downloading #{item_title}…"

      # Set binary
      binary = 'youtube-dl'
      if feed['binary']
        binary = feed['binary']
      end

      # Set options
      options = " --all-subs -o 'downloads/%(title)s-%(id)s.%(ext)s'"
      if feed['options']
        options = " #{feed['options']}"
      end

      # Set pipes
      pipes = ""
      if feed['pipes']
        pipes = " #{feed['pipes']}"
      end

      # Run download task…
      system "#{binary}#{options} #{item_link}#{pipes}"

      # Update log
      log_data = {
        "#{feed_md5}_feed" => feed['url'],
        "#{feed_md5}_updated" => Time.now.to_i,
        "#{feed_md5}_date" => item_date,
        "#{feed_md5}_link" => "#{item_link}",
        "#{feed_md5}_title" => "#{item_title}"
      }
      File.open("log/feed-#{feed_md5}.log", 'w') {|f| f.write(log_data.to_yaml) }
    end
  end
end
