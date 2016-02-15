# for rails 3 transition
#     http://railstips.org/blog/archives/2007/03/04/renaming-rhtml-to-erb/

namespace 'views' do
  desc 'Renames all your rhtml views to erb'
  task 'rename' do
    Dir.glob('app/views/**/*.rhtml').each do |file|
      puts `svn mv #{file} #{file.gsub(/\.rhtml$/, '.html.erb')}`
    end
  end
end
