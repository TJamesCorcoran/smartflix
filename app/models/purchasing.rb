class Purchasing


  #----------
  #    base - all scratched copies
  #----------

  # return a hash: { product_id_1 -> [ polish-copy_id, polish-copy_id ],
  #                  product_id_2 -> [ polish-copy_id, polish-copy_id ] ... }
  def self.polishable_hash
    hash = { }
    Copy.find(:all, :conditions=>"status=0 and death_type_id = 1 and inStock = 1").each do |copy|
      hash[copy.product_id] = Array.new if (hash[copy.product_id].nil?) 
      hash[copy.product_id].push copy.id
    end
    hash
  end

  #----------
  #    three priority tiers
  #----------

  # HIGH
  #
  # like 'med', but we have zero copies in stock
  #
  # return just copy_ids: [ copy_id, copy_id, copy_id ... ]
  def self.polishable_high
    ph = polishable_hash

    subset = ph.select { |product_id, cid_array| p = Product[product_id] ; p.unshipped_lis.size > 0 && p.numLiveCopies() == 0 }.to_hash
    subset.values.flatten

  end

  # MED 
  #
  # Customer is waiting for this copy!
  #
  # return just copy_ids: [ copy_id, copy_id, copy_id ... ]
  def self.polishable_med
    ph = polishable_hash
    subset = ph.select { |product_id, cid_array| p = Product[product_id] ; p.unshipped_lis.size > 0  && p.numLiveCopies() > 0 }.to_hash
    subset.values.flatten
  end

  # LOW
  #
  # return just copy_ids: [ copy_id, copy_id, copy_id ... ]
  def self.polishable_low
    ph = polishable_hash
    subset = ph.select { |product_id, cid_array| Product[product_id].unshipped_lis.size == 0 }.to_hash
    subset.values.flatten
  end

  #----------
  #    util
  #----------


  def self.polished_today
    # XYZ FIX P2: this is wrong, because it also counts things that were fixed via
    # the returns process, etc.  We want to track just those that are polished...
    DeathLog.find_all_by_editDate_and_newDeathType(Date.today, DeathLog::DEATH_NOT_DEAD).map(&:copy)
  end

  def self.dead_today
    # XYZ FIX P2: this is wrong, because it also counts things that were fixed via
    # the returns process, etc.  We want to track just those that are polished...
    DeathLog.find_all_by_editDate_and_newDeathType(Date.today, DeathLog::DEATH_SCRATCHED_IRREVOCABLE).map(&:copy)
  end
  
end

