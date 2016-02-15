class PotentialCopy < PotentialItem

  belongs_to :copy  

  validates_numericality_of :copy_id,      :greater_than => 0
  validates_inclusion_of    :gift_cert_id, :in => [ nil ]

  def gift_cert() nil end
  def boxP() copy.boxP end
  def handout() copy.product.handout end
  def print_name() sprintf("%05i", copy.copy_id) end
end
