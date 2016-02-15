class UpdateLateMsgs < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE line_items change  lateMsg1Sent lateMsg1Sent date AFTER queue_position")
    execute("ALTER TABLE line_items change  lateMsg2Sent lateMsg2Sent date AFTER lateMsg1Sent")
    execute("ALTER TABLE line_items change  lateMsg3Sent lateMsg3Sent date AFTER lateMsg2Sent")
  end

  def self.down
    execute("ALTER TABLE line_items change  lateMsg1Sent lateMsg1Sent date AFTER copy_id")
    execute("ALTER TABLE line_items change  lateMsg2Sent lateMsg2Sent date AFTER lateMsg1Sent")
    execute("ALTER TABLE line_items change  lateMsg3Sent lateMsg3Sent date AFTER return_email_sent")
  end
end
