# XYZFIX P2: explicit paths specified bc tvr-master/app/controllers/usps_postage_forms_controller.rb
# wants to see these file, and can't, unless I do it this way.  WT* ?!?!

require File.dirname(__FILE__) + '/lib/usps_permit_imprint'
require File.dirname(__FILE__) + '/lib/zone_lookup'
require File.dirname(__FILE__) + '/app/models/usps_postage_chart'
