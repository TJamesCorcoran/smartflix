class AddCopiesTable < ActiveRecord::Migration
  def self.up
    create_table 'copies', :primary_key => 'copy_id' do |t|
      t.column 'product_id'       , :integer
      t.column 'birthDATE'        , :date
      t.column 'deathDATE'        , :date
      t.column 'mediaformat'      , :integer
      t.column 'status'           , :integer
      t.column 'inStock'          , :integer
      t.column 'tmpReserve'       , :bool
      t.column 'death_type_id'    , :integer
      t.column 'visibleToShipperP', :bool
      t.column 'payPerRentP'      , :bool
    end
    
    add_index    :copies, :product_id
    add_index    :copies, :birthDATE
    add_index    :copies, :deathDATE
    
    create_table 'line_item_auxes' do |t|
      t.column 'line_item_id'          , :integer, :null => false
      t.column 'format'                , :integer, :null => false, :default => 2
      t.column 'shipment_id'           , :integer
      t.column 'copy_id'               , :integer
      t.column 'dateBack'              , :date
      t.column 'uncancelledP'          , :bool,     :null => false, :default => 1
      t.column 'apologyCopyP'          , :bool
      t.column 'lateMsg1Sent'          , :date
      t.column 'lateMsg2Sent'          , :date
      t.column 'overdueGraceGranted'   , :bool,      :null => false, :default => 0
      t.column 'wrongItemSent'         , :bool,      :null => false, :default => 0
      t.column 'ZcLineItemID'          , :integer
      t.column 'copy_id_intended'      , :integer
      t.column 'return_email_sent'     , :bool,      :null => false, :default => 0
      t.column 'lateMsg3Sent'          , :date
      t.column 'refunded'              , :bool,      :null => false, :default => 0
      t.column 'parent_line_item_id'   , :integer
      t.column 'created_at'            , :datetime
      t.column 'updated_at'            , :datetime
      t.column 'ignore_for_univ_limits', :bool,    :null => false, :default => 0
    end
    
    add_index    :line_item_auxes, :shipment_id
    add_index    :line_item_auxes, :copy_id
    add_index    :line_item_auxes, :dateBack
    add_index    :line_item_auxes, :parent_line_item_id
    
    
    create_table 'shipments', :primary_key => 'shipment_id' do |t|
      t.column 'dateOut'          , :date
      t.column 'dateLost'         , :date
      t.column 'replacedWithOrder', :integer
      t.column 'time_out'         , :datetime, :null => false
      t.column 'email_sent'       , :bool    , :null => false, :default => 0
      t.column 'boxP'             , :bool    , :null => false, :default => 1
      t.column 'physical'         , :bool    , :null => false, :default => 1
    end
    
    add_index    :shipments, :dateOut
end


  def self.down
    drop_table 'copies'
    drop_table 'line_item_auxes'
    drop_table 'shipments'
  end
end
