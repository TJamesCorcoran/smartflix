class AddVerbToUnv < ActiveRecord::Migration
  def self.up
    add_column :universities, :verb_str, :string, :null => true

    { 1 =>"Woodturning", 
      2 =>"Airbrushing", 
      3 =>"Glassworking", 
      4 =>"Jewelry Making", 
      5 =>"Oil Painting", 
      6 =>"Drawing with Pastels", 
      7 =>"Watercolor Painting", 
      8 =>"Welding", 
      9 =>"Woodcarving", 
      10 =>"Dog Agility", 
      11 =>"Culinary Skills", 
      12 =>"Knifemaking", 
      13 =>"Quilting", 
      14 =>"Goldsmithing and Silversmithing", 
      15 =>"Engraving", 
      41 =>"Lampworking", 
      42 =>"Pottery", 
      43 =>"Sewing", 
      44 =>"Screenprinting",
      45 =>"Paper and Ink Skills", 
      46 =>"Blacksmithing", 
      47 =>"Machinist Skills", 
      48 =>"Polymer Clay Skills", 
      49 =>"Wilderness Survival Skills", 
      50 =>"Photoshop", 
      51 =>"Photoshop", 
      57 =>"Maya", 
      58 =>"Zbrush and Mental Ray", 
      59 =>"Digital Painting Skills", 
      60 =>"Guitar", 
      61 =>"Combat Pistol Skills",
      62 =>"Leatherworking", 
      63 =>"Airplane Piloting", 
      64 =>"Videography", 
      65 =>"Sculpture", 
      66 =>"Alternative Energy Skills", 
      67 =>"Electronics", 
      68 =>"Arts & Crafts Skills", 
      69 =>"Physics", 
      70 =>"Biology & Chemistry", 
      71 =>"SAT Prep", 
      72 =>"Custom Auto Skills", 
      73 =>"Fiber Arts", 
      74 =>"Woodworking", 
      76 =>"Photography", 
      77 =>"Construction skills", 
      78 =>"Pioneer skills", 
      79 =>"Lutherie skills", 
      80 =>"Gunsmithing", 
      81 =>"Everything!"
    }.each_pair do |id, verb|
      univ = University.find_by_university_id(id)
      univ.update_attributes(:verb_str => verb) if univ
    end
    
  end
  def self.down
    remove_column :universities, :verb_str
  end
end
