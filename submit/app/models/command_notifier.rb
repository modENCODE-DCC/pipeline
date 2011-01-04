class CommandNotifier < ActionMailer::Base
  MIN_RUNTIME_NOTIFY = 60*10 # Ten minutes
  SUBJECT_TEMPLATE = "A modENCODE submission pipeline notification"
  SUBJECT_TEMPLATE_CHAINING = "Your modENCODE submission has been processed!"
  GEO_SUBJECT_TEMPLATE = "Newly released submissions : GEO & SRA IDs"
  def self.send_batched_notifications
    messages = EmailMessage.all
    logger.info("Sending #{messages.size} batched messages")
    messages_by_recipient = Hash.new { |h, k| h[k] = Array.new }
    messages.each { |msg| messages_by_recipient[msg.to_user].push msg }
    messages_by_recipient.each { |to_user, messages|
      commands_for_liason = messages.find_all { |msg| msg.to_type == "liason" }.map { |msg| msg.command }
      CommandNotifier.deliver_command_notification_for_liason(to_user, commands_for_liason) if commands_for_liason.size > 0
      commands_for_user = messages.find_all { |msg| msg.to_type == "user" }.map { |msg| msg.command }
      CommandNotifier.deliver_command_notification_for_user(to_user, commands_for_user) if commands_for_user.size > 0
      messages.each { |msg| msg.destroy }
    }
    logger.info("Done sending batched messages")
  end
  def self.notify_of_completion(command)
    logger.info("Notifying of completion of command ##{command.id}")
    liasons = get_liasons.keys.map { |l| User.find_by_login(l) }.compact
    user = command.running_user
    liasons = get_liasons_for_pi(user.pis) unless user.nil?
    # User gets an email when a command completes (unless it's one of the simple ones)

    # Don't notify if it was just an expand
    return if command.is_a?(Expand)

    runtime = (command.end_time.nil? || command.start_time.nil?) ? 0 : (command.end_time - command.start_time)

    # Make sure command either suceeded or failed and didn't just end abruptly while still running
    if command.succeeded? || command.failed? then
      # Notify user of command completion
      unless user.nil? || user.email.nil? || liasons.include?(user) || (command.is_a?(Upload) && !command.is_a?(Upload::File::Url)) then
        # Don't notify if they were just uploading from the browser
        # (Don't batch by default)
        user_wants_batched_email = user.preferences["batch"] == "true"
        user_wants_no_email = user.preferences["no_email"] == "true"
        user_wants_all_notifications = user.preferences["all_notifications"] == "true"
        unless user_wants_no_email then
          logger.info("  Notifying user #{user.login} of completion of command ##{command.id}")
          if user_wants_batched_email then
            # Always notify for users with batchmode turned on
            EmailMessage.new(:to_user => user, :command => command, :to_type => "user").save
            logger.info("Saved batch message for #{user.name} <#{user.email}>")
          else
            # Notify immediately unless the command was really short-running and successful
            if runtime >= MIN_RUNTIME_NOTIFY || user_wants_all_notifications || command.failed? then
              CommandNotifier.deliver_command_notification_for_user(user, command)
            end
          end
        end
      end
    end

    # Notify liason of command completion
    liasons.each do |liason|
      next if liason.email.nil?
      logger.info("  Notifying liason #{liason.login} of completion of command ##{command.id}")
      # (Batch by default)
      liason_wants_batched_email = true unless liason.preferences["batch"] == "false"
      liason_wants_no_email = liason.preferences["no_email"] == "true"
      next if liason_wants_no_email
      if liason_wants_batched_email then
        EmailMessage.new(:to_user => liason, :command => command, :to_type => "liason").save
        logger.info("Saved batch message for #{liason.name} <#{liason.email}>")
      else
        CommandNotifier.deliver_command_notification_for_liason(liason, command)
      end
    end
  
  end
 
  # Once a week, send an email notifying about geoids.
  # to_user = single user ; cc_users = an array
  # cc_users = array
  def self.process_geo_notifications(to_user, cc_users, host)
    # Only process emails on Mondays
    return unless Time.now.wday == 1
    cols = ReportsController.get_geoid_columns
    
    new_subs = ReportsController.newly_released_submissions
    sorted_subs = Hash.new
    sorted_subs[:with_geo] = new_subs.reject{|sub|
      sub[cols["GEO/SRA IDs"]].empty?
     }
    sorted_subs[:no_geo] = new_subs.reject{|sub|
      !sub[cols["GEO/SRA IDs"]].empty?
    }
    CommandNotifier.deliver_geo_notification(to_user, cc_users, sorted_subs, host)
    ReportsController.mark_subs_as_notified(new_subs.map{|sub| sub[cols["Submission ID"]]})
  end

  # This method sends an email listing newly released submissions and their GEO / SRA ID.
  def geo_notification(to_user, cc_users, new_subs, hostname)
    recipients  "#{to_user.name} <#{to_user.email}>"
    cc          cc_users.map{|user| "#{user.name} <#{user.email}>"}
    from        "pipeline@modencode.org"
    reply_to    "help@modencode.org"
    subject     GEO_SUBJECT_TEMPLATE
    body        :name => to_user.name.split(/ /).first,
                :subs_with_geo => new_subs[:with_geo],
                :subs_no_geo => new_subs[:no_geo],
                :hostname => hostname
  end

  def command_notification_for_liason(to_user, *commands)
    commands.flatten!
    recipients  "#{to_user.name} <#{to_user.email}>"
    from        "pipeline@modencode.org"
    reply_to    "help@modencode.org"
    subject     SUBJECT_TEMPLATE
    body        :name => to_user.name.split(/ /).first, :commands => commands
  end
  def command_notification_for_user(to_user, *commands)
    commands.flatten!
    recipients  "#{to_user.name} <#{to_user.email}>"
    from        "pipeline@modencode.org"
    reply_to    "help@modencode.org"
    subject     SUBJECT_TEMPLATE
    body        :name => to_user.name.split(/ /).first, :commands => commands
  end

  def self.get_liasons_for_pi(pis)
    usernames = get_liasons.find_all { |liason, lpis| (lpis & pis).size > 0 }.map { |liason, lpis| liason }
    usernames.map { |username|
      begin
        User.find_by_login(username)
      rescue
        nil
      end
    }.compact
  end
  protected
  def self.get_liasons
    if File.exists? "#{RAILS_ROOT}/config/liasons.yml" then
      liasons = open("#{RAILS_ROOT}/config/liasons.yml") { |f| YAML.load(f.read) }
    end
  end
end
