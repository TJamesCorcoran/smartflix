class DeathLog < ActiveRecord::Base
  self.primary_key = "deathLogID"
  attr_protected # <-- blank means total access

  belongs_to :copy
  belongs_to :death_type, :foreign_key => 'newDeathType'

  def to_s()     death_type.name + " - " + self.note.to_s  end
  def date()      editDate  end
  
  private  
  # ATTN CODERS! you probably don't want to ever user this constant hash.
  # You instead want to use the constants that are defined based on this hash, such as
  #   * DeathLog::DEATH_NOT_DEAD
  #   * DeathLog::DEATH_DAMAGED
  #   * etc.
  #
  # You also want to do things like
  #
  #    DeathLog::NOT_CUSTOMER_FAULT_IF_NOT_RETURNED.include?( foobar )
  # 
  # so that all policy decisions are encapsulated here in this class.

  
  # XYZFIX P3: note that this is a duplicate of data that's already in the db.
  # We could replace this with
  #   DeathType.find(:all).collect ...
  STATES_TEXT_TO_CODE = {"DEATH_NOT_DEAD"               => 0,    # The code that's there when it's not dead                                
                         "DEATH_DAMAGED"                => 1,    # Scratched, etc                                                          
                         "DEATH_LOST_IN_TRANSIT"        => 2,    # Lost in the mails                                                       
                         "DEATH_INTERNAL_ERROR"         => 3,    # Mangled and therefore unused lable, etc.                                
                         "DEATH_SOLD"                   => 4,    # We don't have this anymore, we sold it                                  
                         "DEATH_LOST_IN_HOUSE"          => 5,    # Lost by us somehow                                                      
                         "DEATH_RETURNED_TO_VENDOR"     => 6,    # We don't have this anymore, we returned it                              
                         "DEATH_WRONG_CUSTOMER"         => 7,    # We sent it to the wrong customer                                        
                         "DEATH_SCRATCHED_IRREVOCABLE"  => 8,    # Badly badly scratched; cracked; etc                                     
                         "DEATH_LOST_AND_DAMAGED"       => 9,    # both lost and damaged ( DEATH_LOST_IN_TRANSIT +  DEATH_DAMAGED)         
                         "DEATH_LOST_BY_CUST_UNPAID"    => 10,   # customer lost it, has not yet paid                                      

    # 11 existed, briefly.  It was a duplicate of 4.  All changed to 4 now.

                         "DEATH_LOST_BY_CUST_NOADDR"    => 12}   # customer lost it, we sued, snailmail bounced
  public
  STATES_TEXT_TO_CODE.each_pair do |text, code|
    const_set(text, code)
  end
  
  NOT_CUSTOMER_FAULT_IF_NOT_RETURNED = [DEATH_LOST_IN_TRANSIT, 
                                        DEATH_LOST_IN_HOUSE, 
                                        DEATH_LOST_AND_DAMAGED]
  
  SHOULD_NOT_FIND_IN_HOUSE = [DEATH_LOST_IN_TRANSIT, DEATH_LOST_AND_DAMAGED, DEATH_LOST_BY_CUST_UNPAID]

  AUTOMATICALLY_MARK_AS_HEALED = [DEATH_NOT_DEAD, 
                                  DEATH_LOST_IN_TRANSIT,
                                  DEATH_SOLD,
                                  DEATH_LOST_IN_HOUSE,
                                  DEATH_RETURNED_TO_VENDOR,
                                  DEATH_WRONG_CUSTOMER]
  
end
