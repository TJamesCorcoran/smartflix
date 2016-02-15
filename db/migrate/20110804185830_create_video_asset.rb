class CreateVideoAsset < ActiveRecord::Migration
  def self.up
    create_table(:video_assets) do |t|
      t.date :acquired, :null=>false
      t.integer :dollars, :null => false
      t.timestamps  
    end

    VideoAsset.create!(:acquired => Date.parse("2007-01-01"), :dollars=>45642)
    VideoAsset.create!(:acquired => Date.parse("2007-02-01"), :dollars=>34690)
    VideoAsset.create!(:acquired => Date.parse("2007-03-01"), :dollars=>30601)
    VideoAsset.create!(:acquired => Date.parse("2007-04-01"), :dollars=>22963)
    VideoAsset.create!(:acquired => Date.parse("2007-05-01"), :dollars=>26075)
    VideoAsset.create!(:acquired => Date.parse("2007-06-01"), :dollars=>19538)
    VideoAsset.create!(:acquired => Date.parse("2007-07-01"), :dollars=>6215)
    VideoAsset.create!(:acquired => Date.parse("2007-08-01"), :dollars=>35354)
    VideoAsset.create!(:acquired => Date.parse("2007-09-01"), :dollars=>27114)
    VideoAsset.create!(:acquired => Date.parse("2007-10-01"), :dollars=>32138)
    VideoAsset.create!(:acquired => Date.parse("2007-11-01"), :dollars=>12866)
    VideoAsset.create!(:acquired => Date.parse("2007-12-01"), :dollars=>24002)

    VideoAsset.create!(:acquired => Date.parse("2008-01-01"), :dollars=>18996)
    VideoAsset.create!(:acquired => Date.parse("2008-02-01"), :dollars=>22596)
    VideoAsset.create!(:acquired => Date.parse("2008-03-01"), :dollars=>10323)
    VideoAsset.create!(:acquired => Date.parse("2008-04-01"), :dollars=>13132)
    VideoAsset.create!(:acquired => Date.parse("2008-05-01"), :dollars=>7716)
    VideoAsset.create!(:acquired => Date.parse("2008-06-01"), :dollars=>8644)
    VideoAsset.create!(:acquired => Date.parse("2008-07-01"), :dollars=>5569)
    VideoAsset.create!(:acquired => Date.parse("2008-08-01"), :dollars=>4481)
    VideoAsset.create!(:acquired => Date.parse("2008-09-01"), :dollars=>159)
    VideoAsset.create!(:acquired => Date.parse("2008-10-01"), :dollars=>0)
    VideoAsset.create!(:acquired => Date.parse("2008-11-01"), :dollars=>613)
    VideoAsset.create!(:acquired => Date.parse("2008-12-01"), :dollars=>279)

    VideoAsset.create!(:acquired => Date.parse("2009-01-01"), :dollars=>744)
    VideoAsset.create!(:acquired => Date.parse("2009-02-01"), :dollars=>2181)
    VideoAsset.create!(:acquired => Date.parse("2009-03-01"), :dollars=>270)
    VideoAsset.create!(:acquired => Date.parse("2009-04-01"), :dollars=>8640)
    VideoAsset.create!(:acquired => Date.parse("2009-05-01"), :dollars=>6486)
    VideoAsset.create!(:acquired => Date.parse("2009-06-01"), :dollars=>7721)
    VideoAsset.create!(:acquired => Date.parse("2009-07-01"), :dollars=>6595)
    VideoAsset.create!(:acquired => Date.parse("2009-08-01"), :dollars=>3571)
    VideoAsset.create!(:acquired => Date.parse("2009-09-01"), :dollars=>7744)
    VideoAsset.create!(:acquired => Date.parse("2009-10-01"), :dollars=>2694)
    VideoAsset.create!(:acquired => Date.parse("2009-11-01"), :dollars=>6483)
    VideoAsset.create!(:acquired => Date.parse("2009-12-01"), :dollars=>4188)

    VideoAsset.create!(:acquired => Date.parse("2010-01-01"), :dollars=>10021 )
    VideoAsset.create!(:acquired => Date.parse("2010-02-01"), :dollars=>4358  )
    VideoAsset.create!(:acquired => Date.parse("2010-03-01"), :dollars=>15605 )
    VideoAsset.create!(:acquired => Date.parse("2010-04-01"), :dollars=>7874  )
    VideoAsset.create!(:acquired => Date.parse("2010-05-01"), :dollars=>9070  )
    VideoAsset.create!(:acquired => Date.parse("2010-06-01"), :dollars=>7657  )
    VideoAsset.create!(:acquired => Date.parse("2010-07-01"), :dollars=>3203  )
    VideoAsset.create!(:acquired => Date.parse("2010-08-01"), :dollars=>4381  )
    VideoAsset.create!(:acquired => Date.parse("2010-09-01"), :dollars=>6574  )
    VideoAsset.create!(:acquired => Date.parse("2010-10-01"), :dollars=>2732  )
    VideoAsset.create!(:acquired => Date.parse("2010-11-01"), :dollars=>5404  )
    VideoAsset.create!(:acquired => Date.parse("2010-12-01"), :dollars=>2334  )

  end
  
  def self.down
    drop_table(:video_assets)
  end
end
