#!/usr/local/bin/ruby

choices = {
  
  "New: free metalworking DVDs" => 0,
  
  "Free metalworking DVDs" => 0,
  
  "How can you get a month of metalworking DVDs for free?" => 0,
  
  "How can you watch metalworking DVDs for free?" => 0,
  
  "How can you watch metalworking videos for free?" => 0,
  
  "Do you want to learn new metalworking skills for free?" => 0
  
}

results = []

2.times do |ii|
  choices.keys.each do | left |
    choices.keys.each do | right |
      next if left == right
      input = nil
      puts "L: #{left} /// R: #{right}"
      while input != "L" && input != "R"
        input = STDIN.getc.chr.upcase
      end
      if input == "L"
        choices[left] += 1
      else
        choices[right] += 1
      end
      puts choices.inspect
    end
  end
end

puts choices.inspect
