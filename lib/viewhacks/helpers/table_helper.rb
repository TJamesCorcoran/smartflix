


module TableHelper
  def table_from_enumerable(array, cols=3,tableoptions="border=0", tdoptions=nil)
    array = array.tabular_rotate(cols)
    ret = "<table " << tableoptions.to_s << ">"
    array.each do |subarray|
      ret << "<tr>"
      subarray.each do |item|
        ret << "<td " << tdoptions << ">" << item.to_s << "</td>"
      end
      ret << "</tr>"    
    end
    ret << "</table>"
  end
end


ActionView::Base.send :include, TableHelper
