task_name = ARGV.shift

ARGV.each do |pair|
  k, v = pair.split("=")
  ENV[k] = v
end

success = JobRunner::offer(task_name)

