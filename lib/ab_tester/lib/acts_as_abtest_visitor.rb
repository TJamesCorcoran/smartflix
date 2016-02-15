AbTestVisitor

module ActsAsAbtestVisitor
  def acts_as_abt_visitor()
    has_many :ab_test_visitors

    def ab_test_results_hash
      ab_test_visitors.map(&:ab_test_results).flatten.map { |result| [ result.ab_test.name, result.ab_test_option.name ] }.to_hash
    end

  end
  
end


# Extend ActiveRecord 
ActiveRecord::Base.extend ActsAsAbtestVisitor

