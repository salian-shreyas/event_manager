require 'csv'
require 'erb'
require 'google-apis-civicinfo_v2'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue 
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, personal_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts personal_letter
  end
end

# Home-phone of 10 digits is valid
# 11 digit home-phone starting with 1 is valid
def validate_home_phone(home_phone)
  home_phone = home_phone.to_s
  return home_phone.chars.last(10).join.to_i if (home_phone.length == 10) ||
    (home_phone.length == 11 && home_phone[0] == "1")
end

def weekday(wday)
  {
    0 => "Sunday",
    1 => "Monday",
    2 => "Tuesday",
    3 => "Wednesday",
    4 => "Thursday",
    5 => "Friday",
    6 => "Saturday"
  }[wday]
end

puts "Event manager initialized!"

contents = CSV.foreach(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
).map {|row| row}

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  home_phone_= validate_home_phone(row[:homephone])

  puts "#{name}, #{zipcode}, #{home_phone_}"
  # legislators = legislators_by_zipcode(zipcode)
  # personal_letter = erb_template.result(binding)
  # save_thank_you_letter(id, personal_letter)
end

reg_by_hour = contents.reduce(Hash.new(0)) do |reg_by_hour, row|
  reg_hour = Time.strptime(row[:regdate], "%m/%d/%y %H:%M").hour
  reg_by_hour[reg_hour] += 1
  reg_by_hour
end

max_reg = reg_by_hour.values.max
peak_reg_hours = reg_by_hour.reduce([]) do |peak_reg_hours, pair|
  peak_reg_hours.push pair[0] if pair[1] == max_reg
  peak_reg_hours
end
puts "Peak registration hours: #{peak_reg_hours.join(", ")}"

reg_by_wday = contents.reduce(Hash.new(0)) do |reg_by_wday, row|
  reg_wday = Time.strptime(row[:regdate], "%m/%d/%y %H:%M").wday
  reg_by_wday[reg_wday] += 1
  reg_by_wday
end

max_wday_reg = reg_by_wday.values.max
peak_reg_wdays = reg_by_wday.reduce([]) do |peak_reg_wdays, pair|
  peak_reg_wdays.push pair[0] if pair[1] == max_wday_reg
  peak_reg_wdays
end
puts "Peak registration weekdays: #{peak_reg_wdays.map {|wday| weekday(wday)}.join(", ")}"