class PotentialGiftCert < PotentialItem
  self.primary_key ="potential_gift_cert_id"

  belongs_to :gift_cert, :class_name => "Product", :foreign_key => :gift_cert_id

  
  validates_inclusion_of    :copy_id,      :in => [ nil ]
  validates_numericality_of :gift_cert_id, :greater_than => 0

  def copy() nil end
  def boxP() false end
  def handout() nil end
  def print_name() "Gift Cert" end
end
