require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(home_phone)
    #remove anything that is not a number
    #phone numbers are 10 digits
    #if the number is 11 digits and the first is a '1' trim it.
    #if the number is < 10, > 12, or = 11 and the first number isn't '1' it is a bad number.
    phone = home_phone.to_s.gsub( /\D/, "")
    phone = "Invalid phone number." if (phone.length < 10) || (phone.length > 12)
    (phone = phone[1..10]) if ((phone.length == 11) && (phone[0] == '1'))
    phone
end

def optimal_ad_time(date_time)
    #Ruby has a Date library which contains classes for Date and DateTime.
    #DateTime#strptime is a method that allows us to parse date-time strings and convert them into Ruby objects.
    date_object = DateTime.strptime(date_time, format='%m/%d/%Y %H:%M')
    #DateTime#strftime is a good reference on the characters necessary to match the specified date-time format.
    #Use Date#hour to find out the hour of the day.
    date_object.hour
end

def optimal_reg_day(date_time)
    # Use Date#wday to find out the day of the week.
    date_object = DateTime.strptime(date_time, format='%m/%d/%Y %H:%M')
    date_object.day
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

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

def save_thank_you_letter(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts "EventManager initialized."

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
    id = row[0]

    name = row[:first_name]

    zipcode = clean_zipcode(row[:zipcode])

    home_phone = clean_phone_number(row[:homephone])

    time_target = optimal_ad_time(row[:regdate])
    
    day_target = optimal_reg_day(row[:regdate])

    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)
    
    save_thank_you_letter(id, form_letter)

    puts home_phone

    puts time_target

    puts day_target

end



