class Person < ActiveRecord::Base
  self.primary_key = "person_id"
  attr_protected # <-- blank means total access


  has_many :timesheet_items, :foreign_key => :hr_person_id

  has_many :customer_contacts
  has_many :usps_postage_forms

  validates_uniqueness_of :employee_number,  :message => "duplicate employee number", 
  :unless => Proc.new { |person| person.employee_number.nil? }

  def full_name() "#{name_first} #{name_last}" end

  def hours_worked(begin_date, end_date)
    timesheet_items.select { |ts| ts.date >= begin_date && ts.date <= end_date  }.sum { |tsi| tsi.hours_worked }
  end

  def hi_dollars(begin_date, end_date) 
    tax_multiplier = 1.1
    hi_time_fraction * hi_billing * tax_multiplier * hours_worked(begin_date, end_date)
  end

  def self.next_employee_number
    Person.connection.select_one("select max(employee_number) + 1 as 'next' from people")["next"]
  end

  # return all the employees + contractors who are live
  def self.live
    @persons = Person.find(:all, :conditions => "ISNULL(end_date) || end_date > NOW()")
  end
  
  def to_s
    "#{name_first} #{name_last}"
  end

  def self.email_all
    self.find(:all, :conditions => "( ISNULL(end_date) OR end_date > NOW())").map { |person| person.emailaddr.empty_is_nil }.compact.join(", ")
  end

  def self.send_email_all(subj, body)
    to   = (Rails.env == 'production') ? email_all : SmartFlix::Application::EMAIL_TO_DEVELOPER     
    SfMailer.simple_message(to, SmartFlix::Application::EMAIL_FROM, subj, body)
  end

  # Support arbitrary "mail this person/ these people" commands based
  #    on columns in the table
  #
  #
  # self.email_polishing      - get the email addrs of folks who have this bit set
  # self.send_email_polishing - send the email to these folks
  # self.!@#%#                - boot it upstairs
  def self.method_missing(method, *args)
    if method.to_s.match(/^(email_.*)/) && columns.detect {|col| col.name == method.to_s }
      self.find(:all, :conditions => "#{$1} = 1 and ( ISNULL(end_date) OR end_date > NOW())").map { |person| person.emailaddr }.join(", ")
    elsif method.to_s.match(/^send_(email_.*)/)
      to   = (Rails.env == 'production') ? self.send($1) : SmartFlix::Application::EMAIL_TO_DEVELOPER 
      subj = args[0]
      body = args[1]
      raise "no recipients specified for email" if to.empty?
      SfMailer.simple_message(to, SmartFlix::Application::EMAIL_FROM, subj, body)
      "sent '#{subj}' email to #{to }\n\n#{ body }"
    else
      super method, *args
    end
  end

  # return a list of all current employee's email addrs 
  def self.current_email_addrs
    Person.find(:all, :conditions => "ISNULL(end_date)").map(&:emailaddr).join(",")
  end

  def dollars_last_14_days
    
  end
  
end
