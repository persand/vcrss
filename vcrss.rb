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
  feed_md5.update "#{feed['url']}-#{i}"
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
  if !log["#{feed_md5}_last_pub_date"]
    last_pub_date = 0
  else
    last_pub_date = log["#{feed_md5}_last_pub_date"].to_i
  end

  # Load last downloaded link for feed
  if !log["#{feed_md5}_last_link"]
    last_link = ''
  else
    last_link = log["#{feed_md5}_last_link"]
  end

  # Read feed
  rss = RSS::Parser.parse(feed['url'], false)
  new_pub_date = 0
  new_link = ''

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

    # Check if to filter content and only download specific items
    if feed['filters']
      download = false

      feed['filters'].each do |filter|
        if item_title.include? "#{filter}"
          download = true
        end
      end
    end

    # Check if the item already has been downloaded
    if item_date >= last_pub_date
      if item_link == last_link
        download = false
      end
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

      # Set new latest downloaded info
      new_link = item_link
      new_pub_date = item_date
    end
  end

  # Update log if any new content was downloaded
  if new_pub_date >= last_pub_date
    log_data = {
      "#{feed_md5}_updated" => Time.now.to_i,
      "#{feed_md5}_last_pub_date" => new_pub_date,
      "#{feed_md5}_last_link" => new_link
    }
    File.open("log/feed-#{feed_md5}.log", 'w') {|f| f.write(log_data.to_yaml) }
  end
end
