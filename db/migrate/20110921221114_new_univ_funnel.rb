class NewUnivFunnel < ActiveRecord::Migration
  def self.up
#    AbTest.all.each { |x| AbTest.complete_destroy(x.name) } 
    AbTester.create_test("NewUnivFunnel",  1, 0.0, [:new_univ_false, :new_univ_indiv, :new_univ_only], true)
  end

  def self.down
    AbTest.complete_destroy("NewUnivFunnel")
  end
end
