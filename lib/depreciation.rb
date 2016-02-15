# Purpose: 
#
# Calculate the amount of depreciation to take in a given month, based on
#    http://helium/mediawiki/index.php/Depreciation
# which references 
#    http://www.irs.gov/businesses/small/article/0,,id=141492,00.html
# which references
#    IRS Revenue Ruling 89-62
#----------
#
# algorithm:
# assume N month depreciation schedule (for us, N=36).
#
# 1) build array of months, with N empty (0) spaces at the front.  
#    Into each, put the amount spent on videos that month.
#
# 2) sum the N empty spaces.  Store this number.  Divide by N, print out.  That's the depreciation for month i.
#
# 3) Shift the window 1 to the right.  Subtract the month falling off; add the month added on.
#    (re)-store this number.  Divide by N, print out.  That's the depreciation for month i + 1.
#
# 4) etc.

class Depreciation
  
  def self.calculate()
    # Find expenses
    #
    # Arrays are indexed by cardinal month after 0 AD.
    # Thus, expenses in Feb of 3 AD are in slot (3 * 12 ) + 2 = 38
    expense = Hash.new(0.0)
    ActiveRecord::Base.connection.select_all("
      SELECT year(date) *12 + month(date) as 'index', sum(amount) as 'amt' 
      FROM gnucash 
      WHERE category='Videos' 
      GROUP BY year(date), month(date) 
      ORDER BY year(date), month(date)").each  { |row| expense[ row["index"].to_i] = row["amt"].to_f }

    # calculate depreciations - O(m * n) ... but both terms are small
    full_run = 120
    straightline_count = 36
    depreciation = Hash.new(0.0)
    firstMonthIndex = expense.keys.min
    (firstMonthIndex .. firstMonthIndex + full_run).each do | exp_month |
      (exp_month .. (exp_month + straightline_count) ).each do | dep_month |
        depreciation[dep_month] += (expense[exp_month] / straightline_count)
      end
    end

    { :expense => expense, :depreciation => depreciation}
  end
  

  def self.report(depreciation)
    ret = ""
    firstMonthIndex = depreciation.keys.min
    (firstMonthIndex..(firstMonthIndex+ 120)).each do | month |
      yy = month / 12
      mm = month % 12 
      dep = ("%.2f" % depreciation[month]).reverse.gsub(/......(?=.)/,'\&,').reverse
      ret << "#{yy}, #{"%2i" % (mm+1)}: $#{dep}\n"
    end
    ret
  end

end
