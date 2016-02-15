class BookkeeperJobOpening < ActiveRecord::Migration
  def self.up
    JobOpening.create(:name => "Bookkeeper",

:description => "We need a bookkeeper to work in our Arlington Center
office around 2-4 hours per week.  Tasks include opening bills,
cutting checks, noting expenditures and receipts in QuickBooks Online,
emailing our payroll firm our bi-weekly payroll numbers, and very
light filing. 

<br><br> The hours are very flexible, the work
environment is very casual, the people are friendly (and so is the occassional dog that wanders through).  

<br><br>
Say hello to your friendly co-workers, listen to your ipod, drink a free soda or espresso, and get the work done on your schedule.
",

                      :compensation => "$15/hr")
  end

  def self.down
  end
end
