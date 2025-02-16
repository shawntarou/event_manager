require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(phonenumber)
  number = ''
  phonenumber.chars.each do |char|
    if Integer(char, exception: false) 
      number += phonenumber[char].chr
    end
  end
  if number.length == 11
    if number[0] == '1'
      number[1...]
    else
      'Bad Number'
    end
  elsif number.length == 10
    number
  else
    'Bad Number'
  end
end

def clean_time_and_date(time_and_date)
  time_and_date_array = time_and_date.split(' ')
  date = time_and_date_array[0].split('/')
  time = time_and_date_array[1].split(':')
  year = '20' + date[2] 
  month = date[0]
  day = date[1]
  hour = time[0] 
  minute = time[1]
  clean_time = Time.new(year, month, day, hour, minute)
  return clean_time
  #puts cleanime.strftime("%m/%d/%Y @ %k:%M")
end

def get_top3_reg_hours(reg_hours)
  reg_hours_hash = Hash.new(0)
  reg_hours.each {|hour| reg_hours_hash[hour] += 1}
  reg_hours_hash = reg_hours_hash.sort_by { |_, value| value }.to_h()
  top3_reg_hours = ["#{reg_hours_hash.keys[-1]}:00", "#{reg_hours_hash.keys[-2]}:00", "#{reg_hours_hash.keys[-3]}:00"]
  puts top3_reg_hours
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
reg_hours = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_numbers = clean_phone_numbers(row[:homephone]) 
  time_and_date = clean_time_and_date(row[:regdate])
  reg_hours.append(time_and_date.hour)

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  #save_thank_you_letter(id, form_letter)
end

get_top3_reg_hours(reg_hours)