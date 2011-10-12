@buzzard_events = [
  :failed_to_send_mt,
  :mt_sending_error,
  :dr_request_received,
  :mo_request_received,
  :mt_sent
]

@operators = [
  :uk_o2,
  :uk_orange,
  :uk_vodafone,
  :uk_tmobile,
  :uk_three,
  :ie_three,
  :ie_meteor,
  :ie_vodafone,
  :ie_o2,
  :ipx,
  :reach_data
]

@operators.each do |operator|
  puts "div.#{operator} {"
  puts "\tbackground-color: @#{operator};"
  puts "}"
end

@buzzard_events.each do |event|
   @operators.each do |operator|
      puts ".#{event}_#{operator} {"
      puts "\tstroke: @#{operator};"
      puts "}"
      puts "circle.#{event}_#{operator} {"
      puts "\tfill: @#{operator};"
      puts "}"
   end
end
