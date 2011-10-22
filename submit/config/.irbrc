# irb file shared for all script/console users.

require 'irb/completion'
# If you would like to have pre-completion history, enable these.
#require 'irb/ext/save-history'
#IRB.conf[:SAVE_HISTORY] = 1000
#IRB.conf[:HISTORY_FILE] = "/var/www/submit/log/console.history" 

# Add a special message for a special user
if ENV['USER_SPECIFIC_HOME'] == "/u/plloyd" then
  print case rand(30)
      when 0
        "Welcome to the Rails Console! No, really, welcome!\n"
      when 1
        "Good luck. And boy do you need it.\n"
      when 2
        "Oh, it's you again?\n"
      when 3
        "I'm sure you won't break anything, this time.\n"
      when 4
        "Remember, nobody will judge you if you ask for help.\n"
      when 5
        "Hi there!\n"
      when 6
        "It's a beautiful day today, here, in Canada.\n"
      when 7
        "Your lucky numbers for today are: #{rand(100)} #{rand(100)} #{rand(100)} #{rand(100)} #{rand(100)}!\n"
      when 8
        "Don't you feel like going to get some frozen yoghurt?\n"
      when 9
        "Ooh, it's great to see you're getting some work done!\n\n"
      when 10
        "type 'quit', 'exit', or 'Ctrl-d' when you want to get the heck out of here!\n"
      when 11
        "Is this something you should be doing in screen?\n"
      when 12
        "Hello, Paul.\n"
      when 13
        "We are always watching you.\n"
      when 14
        "I bet you'd rather be riding your bike."
      else ""
  end
end

# Log user input to console.log
module Readline
  module History
    LOG = File.dirname(__FILE__) + '/../log/console.log' 
    usr_home = ENV['USER_SPECIFIC_HOME'] 
    USER = usr_home.nil? ? "unknown" : File.basename(usr_home)

    def self.write_log(line)
      File.open(LOG, 'ab') {|f| f << "#{USER}: #{line}\n"}
    end

    def self.start_session_log
      write_log("# session start: #{Time.now}")
      at_exit { write_log("# session stop: #{Time.now}") }
    end
  end

  alias :old_readline :readline
  def readline(*args)
    ln = old_readline(*args)
    begin
      History.write_log(ln)
    rescue
    end
    ln
  end
end

Readline::History.start_session_log

