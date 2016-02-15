class CreateStates < ActiveRecord::Migration

  def self.up

    create_table(:states, :primary_key => 'state_id') do |t|
      t.column :name, :string, :null => false
      t.column :code, :string, :null => false
    end

    # Pre-populate this table with US states; we specify the IDs
    # directly to ensure that they are the same as in Zencart to make
    # the mapping easier and to do that we need to do direct SQL since
    # create always uses default IDs

    execute "INSERT INTO states (state_id, name, code) VALUES (1, 'Alabama', 'AL')"
    execute "INSERT INTO states (state_id, name, code) VALUES (2, 'Alaska', 'AK')"
    execute "INSERT INTO states (state_id, name, code) VALUES (3, 'American Samoa', 'AS')"
    execute "INSERT INTO states (state_id, name, code) VALUES (4, 'Arizona', 'AZ')"
    execute "INSERT INTO states (state_id, name, code) VALUES (5, 'Arkansas', 'AR')"
    execute "INSERT INTO states (state_id, name, code) VALUES (6, 'Armed Forces Africa', 'AF')"
    execute "INSERT INTO states (state_id, name, code) VALUES (7, 'Armed Forces Americas', 'AA')"
    execute "INSERT INTO states (state_id, name, code) VALUES (8, 'Armed Forces Canada', 'AC')"
    execute "INSERT INTO states (state_id, name, code) VALUES (9, 'Armed Forces Europe', 'AE')"
    execute "INSERT INTO states (state_id, name, code) VALUES (10, 'Armed Forces Middle East', 'AM')"
    execute "INSERT INTO states (state_id, name, code) VALUES (11, 'Armed Forces Pacific', 'AP')"
    execute "INSERT INTO states (state_id, name, code) VALUES (12, 'California', 'CA')"
    execute "INSERT INTO states (state_id, name, code) VALUES (13, 'Colorado', 'CO')"
    execute "INSERT INTO states (state_id, name, code) VALUES (14, 'Connecticut', 'CT')"
    execute "INSERT INTO states (state_id, name, code) VALUES (15, 'Delaware', 'DE')"
    execute "INSERT INTO states (state_id, name, code) VALUES (16, 'District of Columbia', 'DC')"
    execute "INSERT INTO states (state_id, name, code) VALUES (17, 'Federated States Of Micronesia', 'FM')"
    execute "INSERT INTO states (state_id, name, code) VALUES (18, 'Florida', 'FL')"
    execute "INSERT INTO states (state_id, name, code) VALUES (19, 'Georgia', 'GA')"
    execute "INSERT INTO states (state_id, name, code) VALUES (20, 'Guam', 'GU')"
    execute "INSERT INTO states (state_id, name, code) VALUES (21, 'Hawaii', 'HI')"
    execute "INSERT INTO states (state_id, name, code) VALUES (22, 'Idaho', 'ID')"
    execute "INSERT INTO states (state_id, name, code) VALUES (23, 'Illinois', 'IL')"
    execute "INSERT INTO states (state_id, name, code) VALUES (24, 'Indiana', 'IN')"
    execute "INSERT INTO states (state_id, name, code) VALUES (25, 'Iowa', 'IA')"
    execute "INSERT INTO states (state_id, name, code) VALUES (26, 'Kansas', 'KS')"
    execute "INSERT INTO states (state_id, name, code) VALUES (27, 'Kentucky', 'KY')"
    execute "INSERT INTO states (state_id, name, code) VALUES (28, 'Louisiana', 'LA')"
    execute "INSERT INTO states (state_id, name, code) VALUES (29, 'Maine', 'ME')"
    execute "INSERT INTO states (state_id, name, code) VALUES (30, 'Marshall Islands', 'MH')"
    execute "INSERT INTO states (state_id, name, code) VALUES (31, 'Maryland', 'MD')"
    execute "INSERT INTO states (state_id, name, code) VALUES (32, 'Massachusetts', 'MA')"
    execute "INSERT INTO states (state_id, name, code) VALUES (33, 'Michigan', 'MI')"
    execute "INSERT INTO states (state_id, name, code) VALUES (34, 'Minnesota', 'MN')"
    execute "INSERT INTO states (state_id, name, code) VALUES (35, 'Mississippi', 'MS')"
    execute "INSERT INTO states (state_id, name, code) VALUES (36, 'Missouri', 'MO')"
    execute "INSERT INTO states (state_id, name, code) VALUES (37, 'Montana', 'MT')"
    execute "INSERT INTO states (state_id, name, code) VALUES (38, 'Nebraska', 'NE')"
    execute "INSERT INTO states (state_id, name, code) VALUES (39, 'Nevada', 'NV')"
    execute "INSERT INTO states (state_id, name, code) VALUES (40, 'New Hampshire', 'NH')"
    execute "INSERT INTO states (state_id, name, code) VALUES (41, 'New Jersey', 'NJ')"
    execute "INSERT INTO states (state_id, name, code) VALUES (42, 'New Mexico', 'NM')"
    execute "INSERT INTO states (state_id, name, code) VALUES (43, 'New York', 'NY')"
    execute "INSERT INTO states (state_id, name, code) VALUES (44, 'North Carolina', 'NC')"
    execute "INSERT INTO states (state_id, name, code) VALUES (45, 'North Dakota', 'ND')"
    execute "INSERT INTO states (state_id, name, code) VALUES (46, 'Northern Mariana Islands', 'MP')"
    execute "INSERT INTO states (state_id, name, code) VALUES (47, 'Ohio', 'OH')"
    execute "INSERT INTO states (state_id, name, code) VALUES (48, 'Oklahoma', 'OK')"
    execute "INSERT INTO states (state_id, name, code) VALUES (49, 'Oregon', 'OR')"
    execute "INSERT INTO states (state_id, name, code) VALUES (50, 'Palau', 'PW')"
    execute "INSERT INTO states (state_id, name, code) VALUES (51, 'Pennsylvania', 'PA')"
    execute "INSERT INTO states (state_id, name, code) VALUES (52, 'Puerto Rico', 'PR')"
    execute "INSERT INTO states (state_id, name, code) VALUES (53, 'Rhode Island', 'RI')"
    execute "INSERT INTO states (state_id, name, code) VALUES (54, 'South Carolina', 'SC')"
    execute "INSERT INTO states (state_id, name, code) VALUES (55, 'South Dakota', 'SD')"
    execute "INSERT INTO states (state_id, name, code) VALUES (56, 'Tennessee', 'TN')"
    execute "INSERT INTO states (state_id, name, code) VALUES (57, 'Texas', 'TX')"
    execute "INSERT INTO states (state_id, name, code) VALUES (58, 'Utah', 'UT')"
    execute "INSERT INTO states (state_id, name, code) VALUES (59, 'Vermont', 'VT')"
    execute "INSERT INTO states (state_id, name, code) VALUES (60, 'Virgin Islands', 'VI')"
    execute "INSERT INTO states (state_id, name, code) VALUES (61, 'Virginia', 'VA')"
    execute "INSERT INTO states (state_id, name, code) VALUES (62, 'Washington', 'WA')"
    execute "INSERT INTO states (state_id, name, code) VALUES (63, 'West Virginia', 'WV')"
    execute "INSERT INTO states (state_id, name, code) VALUES (64, 'Wisconsin', 'WI')"
    execute "INSERT INTO states (state_id, name, code) VALUES (65, 'Wyoming', 'WY')"

    # Prepopulate this table with Canadian provinces
    execute "INSERT INTO states (state_id, name, code) VALUES (66, 'Alberta', 'AB')"
    execute "INSERT INTO states (state_id, name, code) VALUES (67, 'British Columbia', 'BC')"
    execute "INSERT INTO states (state_id, name, code) VALUES (68, 'Manitoba', 'MB')"
    execute "INSERT INTO states (state_id, name, code) VALUES (69, 'Newfoundland', 'NF')"
    execute "INSERT INTO states (state_id, name, code) VALUES (70, 'New Brunswick', 'NB')"
    execute "INSERT INTO states (state_id, name, code) VALUES (71, 'Nova Scotia', 'NS')"
    execute "INSERT INTO states (state_id, name, code) VALUES (72, 'Northwest Territories', 'NT')"
    execute "INSERT INTO states (state_id, name, code) VALUES (73, 'Nunavut', 'NU')"
    execute "INSERT INTO states (state_id, name, code) VALUES (74, 'Ontario', 'ON')"
    execute "INSERT INTO states (state_id, name, code) VALUES (75, 'Prince Edward Island', 'PE')"
    execute "INSERT INTO states (state_id, name, code) VALUES (76, 'Quebec', 'QC')"
    execute "INSERT INTO states (state_id, name, code) VALUES (77, 'Saskatchewan', 'SK')"
    execute "INSERT INTO states (state_id, name, code) VALUES (78, 'Yukon Territory', 'YT')"

  end

  def self.down
    drop_table :states
  end
end
