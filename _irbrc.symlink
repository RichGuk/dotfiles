require 'irb/completion'
require 'irb/ext/save-history'
IRB.conf[:SAVE_HISTORY] = 100
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-save-history"

if defined?(Stinkyink)
  # Enable Auditing
  if defined?(Auditor) && Rails.env.development?
    Auditor::User.current_user = User.find_by_email("rich@stinkyink.com")
  end
end
