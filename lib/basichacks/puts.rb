def iputs(arg)
  puts ("  " * (caller(0).size - 4)) + arg
end
