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

puts "Event manager initialized!"

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  home_phone_= validate_home_phone(row[:homephone])

  # legislators = legislators_by_zipcode(zipcode)
  # personal_letter = erb_template.result(binding)
  # save_thank_you_letter(id, personal_letter)
end