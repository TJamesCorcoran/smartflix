require 'action_view/helpers/asset_tag_helper'

module ActionView
  module Helpers
    module AssetTagHelper
      require 'jsminlib'


      def compress_css(source)
        source.gsub!(/\s+/, " ")           # collapse space
        source.gsub!(/\/\*(.*?)\*\/ /, "") # remove comments
        source.gsub!(/\} /, "}\n")         # add line breaks
        source.gsub!(/\n$/, "")            # remove last break
        source.gsub!(/ \{ /, " {")         # trim inside brackets
        source.gsub!(/; \}/, "}")          # trim inside brackets
      end
      
      def get_file_contents(filename)
        contents = File.read(filename)
        if filename =~ /\.js$/
          JSMin.minimize(contents)
        elsif filename =~ /\.css$/
          compress_css(contents)
        end
      end

       def join_asset_file_contents(paths)
         paths.collect { |path|
           get_file_contents(File.join(ASSETS_DIR, path.split("?").first)) }.join("\n\n")
       end
      
    end
  end
end
