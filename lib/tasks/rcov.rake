namespace :test do

  desc "run rcov; create ./coverage/index.html"
  task :rcov do |t|
    #   sh "rcov --text-coverage-diff --no-color test/unit/*.rb"
    sh "rcov test/unit/*.rb"
    puts "look at file:///home/xyz/bus/tvr/src/rails/railscart/coverage/index.html"
  end

end
