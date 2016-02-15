def select_year_21(date, options = {}, html_options = {})
  val = date ? (date.kind_of?(Fixnum) ? date : date.year) : ''
  if options[:use_hidden]
    hidden_html(options[:field_name] || 'year', val, options)
  else
    year_options = []
    y = date ? (date.kind_of?(Fixnum) ? (y = (date == 0) ? Date.today.year : date) : date.year) : Date.today.year

    start_year, end_year = (options[:start_year] || y-5), (options[:end_year] || y+5)
    step_val = start_year < end_year ? 1 : -1
    start_year.step(end_year, step_val) do |year|
      year_options << ((val == year) ?
        content_tag(:option, year, :value => year, :selected => "selected") :
        content_tag(:option, year, :value => year)
      )
      year_options << "\n"
    end
    select_html_21(options[:field_name] || 'year', year_options.join, options, html_options)
  end
end


def select_month_21(date, options = {}, html_options = {})
  val = date ? (date.kind_of?(Fixnum) ? date : date.month) : ''
  if options[:use_hidden]
    hidden_html(options[:field_name] || 'month', val, options)
  else
    month_options = []
    month_names = options[:use_month_names] || (options[:use_short_month] ? Date::ABBR_MONTHNAMES : Date::MONTHNAMES)
    month_names.unshift(nil) if month_names.size < 13
    1.upto(12) do |month_number|
      month_name = if options[:use_month_numbers]
                     month_number
                   elsif options[:add_month_numbers]
                     month_number.to_s + ' - ' + month_names[month_number]
                   else
                     month_names[month_number]
                   end

      month_options << ((val == month_number) ?
                        content_tag(:option, month_name, :value => month_number, :selected => "selected") :
                        content_tag(:option, month_name, :value => month_number)
                        )
      month_options << "\n"
    end
    select_html_21(options[:field_name] || 'month', month_options.join, options, html_options)
  end
end

def select_html_21(type, html_options, options, select_tag_options = {})
#    name_and_id_from_options(options, type)
    select_options = {:id => options[:id], :name => options[:name]}
    select_options.merge!(:disabled => 'disabled') if options[:disabled]
    select_options.merge!(select_tag_options) unless select_tag_options.empty?
    select_html = "\n"
    select_html << content_tag(:option, '', :value => '') + "\n" if options[:include_blank]
    select_html << html_options.to_s
    content_tag(:select, select_html, select_options) + "\n"
  end

def radio_button_tag_21(name, value, checked = false, options = {} )
  pretty_tag_value = value.to_s.gsub(/\s/, "_").gsub(/(?!-)\W/, "").downcase
  pretty_name = name.to_s.gsub(/\[/, "_").gsub(/\]/, "")
  html_options = { "type" => "radio", "name" => name, "id" => "#{pretty_name}_#{pretty_tag_value}", "value" => value }.update(options.stringify_keys)
  html_options["checked"] = "checked" if checked
  tag :input, html_options
end

