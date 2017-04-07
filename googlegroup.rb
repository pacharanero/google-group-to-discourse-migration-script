require 'fileutils'

  # for usage instructions see the README.md of the originating repo

  def setup(google_group_name=ARGV[0], cookie_path=ARGV[1])
    # install dependencies
    # system 'apt install sqlite3 libsqlite3-dev git'
    # system 'gem install sqlite3'
    # system 'su - discourse'

    # (note that these env vars are only set within the scope of Ruby, not the parent shell)
    # set environment variables for icy/google-group-crawler
    ENV["_GROUP"] = google_group_name
    ENV['_WGET_OPTIONS'] = "--load-cookies #{cookie_path} --keep-session-cookies"

    puts "\n\nGoogle Group name is #{ENV["_GROUP"]}".red
    puts "Google Group URL should be https://groups.google.com/forum/#!forum/#{ENV['_GROUP']}".blue
    puts "If you experience problems with the export then check this URL is correct".blue

    # set environment variables for discourse mbox importer
    ENV['MBOX_SUBDIR'] = "mbox"                   # subdirectory with mbox files is 'mbox'
    ENV['LIST_NAME'] = ""                         # this will remove [google_group_name] text from the Subject of each post, if required
    ENV['DATA_DIR'] = "./googlegroup-export/#{google_group_name}"   # subdirectory into which the mbox files have been saved
    ENV['SPLIT_AT'] = "^From "                    # or "^From (.*)"
  end

  def scrape_google_group_to_mbox
    puts "\n\nCloning the Google Group export script from https://github.com/icy/google-group-crawler".red
    system "git clone https://github.com/icy/google-group-crawler googlegroup-export"

    Dir.chdir "googlegroup-export" do
      system 'chmod +x ./crawler.sh'

      puts "\n\nStarting first pass collection of topics".red
      puts "This stage can take minutes to hours, depending on the size of your Google Group\n\n".blue

      system './crawler.sh -sh > wget.sh'
      system 'chmod +x ./wget.sh'

      puts "\n\nIterating through topics to get messages\n\n".red
      puts "This stage takes longer than the first pass and can take hours, depending on the size of your Google Group\n\n".blue
      system './wget.sh'
      system "chmod -R 777 #{ENV["_GROUP"]}"
    end
  end

  def import_to_discourse
    puts "\n\nStarting import of mbox messages into Discourse".red
    puts "This stage can take minutes to hours, depending on the size of your Google Group\n\n".blue
    require_relative 'mbox.rb'

    puts "\n\nMigration from Google Groups to Discourse complete".magenta
  end

  # this monkey-patching of the String class is only in here to do pretty colours in the terminal
  class String
    def red;            "\e[31m#{self}\e[0m" end
    def green;          "\e[32m#{self}\e[0m" end
    def brown;          "\e[33m#{self}\e[0m" end
    def blue;           "\e[34m#{self}\e[0m" end
    def magenta;        "\e[35m#{self}\e[0m" end
    def cyan;           "\e[36m#{self}\e[0m" end
    def gray;           "\e[37m#{self}\e[0m" end
  end


setup
scrape_google_group_to_mbox
import_to_discourse
