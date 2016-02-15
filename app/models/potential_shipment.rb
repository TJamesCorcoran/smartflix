 require 'erb_helper'

class PotentialShipment < ActiveRecord::Base
  self.primary_key ="potential_shipment_id"

  attr_protected # <-- blank means total access


  belongs_to :customer
  has_many :potential_items
  has_many :potential_gift_certs
  has_many :potential_copies
  
  def boxP
    potential_items.size > 4 || 
      (potential_items.detect { |item|  item.boxP } && true) ||
      customer.customs?      
  end

  def cancel
    destroy_self_and_children( [ :potential_items ] )
  end
      
  #  What type of shipment is this? One item? Two? Handouts? Canada?
  def sort_text
    besort =  boxP ? "B-" : "E-"
    count = potential_items.size
    canada = customer.customs?
    handout = !! potential_items.map(&:handout).detect { |ho| ! ho.andand.empty_is_nil.nil?}
    giftcert = false # XYZFIX P1
    
    if (canada) 
      tsort = 'T7' ; # Canada
    elsif (handout) 
      tsort = 'T6'  # Handout
    elsif (count > 4) 
      tsort = 'T5'  # Many
    elsif (count == 4) 
      tsort = 'T4'  # 4
    elsif (count == 3) 
      tsort = 'T3'  # 3
    elsif (count == 2) 
      tsort = 'T2'  # 2
    elsif (count == 1) 
      tsort = 'T1'  # 1
    elsif (giftcert) 
      tsort = 'GC'
    end
    
    dsort = potential_items.map(&:print_name).sort.first
    besort + tsort + dsort
  end

  STICKER_FILE = "#{Rails.root}/app/views/admin/shipments/sticker_template.tex"
  def print_label
    base_name = "/tmp/#{String.random_alphanumeric}"
    
    `barcode -E -n -c -b #{self.barcode} -e 39 -o #{base_name}.eps`
    
    data = { :boxP  => self.boxP,
      :copies       => self.potential_copies.map(&:copy) ,
      :gift_certs   => self.potential_gift_certs.map{|pgc| pgc.gift_cert.name.latex_escape } ,
      :barcode_file => "#{base_name}.eps",
      :customsP     => self.customer.customs?, 
      :shipping_address => self.customer.shipping_address.to_s.latex_escape }
    
    open(base_name, "w") {  |f| xx = ErbHelper.template_file(STICKER_FILE, data)
      f << xx
    }
    
    `(cd /tmp; latex #{base_name}  )`
    `(cd /tmp; dvips -f  #{base_name}.dvi > #{base_name}.ps)`

    if (Rails.env == 'production')
      `(cd /tmp; lp -d #{SmartFlix::Application::BACKEND_PRINTER_NAME} #{base_name}.ps )`
    else
      `(cd /tmp; gs #{base_name}.ps)`
    end

    if (Rails.env == 'production')
      `(cd /tmp; rm  #{base_name}.* )` 
    else
      puts "**** #{base_name}"
    end
  end
end
    
