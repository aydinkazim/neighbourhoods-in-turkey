# frozen_string_literal: true

require 'faraday'
require 'nokogiri'

# Faraday bağlantısı
ptt = Faraday.new('https://postakodu.ptt.gov.tr/') do |faraday|
  faraday.request(:url_encoded)
  faraday.response(:logger)
  faraday.adapter(Faraday.default_adapter)
end

def get_hidden_fields(response_body)
  html_body = Nokogiri::HTML(response_body)
  viewstate = html_body.at('input[name="__VIEWSTATE"]')['value']
  event_validation = html_body.at('input[name="__EVENTVALIDATION"]')['value']
  { viewstate:, event_validation: }
end

def get_cookie_from_response(response)
  cookie_header = response.headers['set-cookie']
  cookie_header&.split(';')&.first
end

# İlk adım: Sayfanın ilk halini çek (GET isteği)
initial_response = ptt.get('/')
initial_body = initial_response.body
cookies = get_cookie_from_response(initial_response)
hidden_fields = get_hidden_fields(initial_body)

# Tüm şehirleri al
html_body = Nokogiri::HTML(initial_body)
cities = html_body.css('select#MainContent_DropDownList1 option').map do |option|
  { value: option['value'], text: option.text.strip } unless option['value'] == '-1'
end.compact

# Sadece ilk şehir için çalıştır
cities.first(1).each do |city|
  puts "Şehir: #{city[:text]}"

  # Şehir seçili olarak POST isteği
  ptt_response = ptt.post(
    '/',
    {
      'ctl00$MainContent$DropDownList1' => city[:value],
      '__EVENTTARGET' => 'ctl00$MainContent$DropDownList1',
      '__EVENTARGUMENT' => '',
      '__VIEWSTATE' => hidden_fields[:viewstate],
      '__EVENTVALIDATION' => hidden_fields[:event_validation],
    },
    { 'Cookie' => cookies },
  )

  # İlçeleri parse et
  response_body = ptt_response.body
  hidden_fields = get_hidden_fields(response_body)
  cookies = get_cookie_from_response(ptt_response)
  html_body = Nokogiri::HTML(response_body)

  districts = html_body.css('select#MainContent_DropDownList2 option').map do |option|
    { value: option['value'], text: option.text.strip } unless option['value'] == '-1'
  end.compact

  # Her ilçe için mahalleleri çek
  districts.each do |district|
    puts "  İlçe: #{district[:text]}"

    # İlçe seçili olarak POST isteği
    ptt_response = ptt.post(
      '/',
      {
        'ctl00$MainContent$DropDownList1' => city[:value],
        'ctl00$MainContent$DropDownList2' => district[:value],
        '__EVENTTARGET' => 'ctl00$MainContent$DropDownList2',
        '__EVENTARGUMENT' => '',
        '__VIEWSTATE' => hidden_fields[:viewstate],
        '__EVENTVALIDATION' => hidden_fields[:event_validation],
      },
      { 'Cookie' => cookies },
    )

    # Mahalleleri parse et
    response_body = ptt_response.body
    hidden_fields = get_hidden_fields(response_body)
    cookies = get_cookie_from_response(ptt_response)
    html_body = Nokogiri::HTML(response_body)

    neighborhoods = html_body.css('select#MainContent_DropDownList3 option').map do |option|
      { value: option['value'], text: option.text.strip } unless option['value'] == '-1'
    end.compact

    neighborhoods.each do |neighborhood|
      puts "    Mahalle: #{neighborhood[:text]} - Posta Kodu: #{neighborhood[:value]}"
    end
  end
end
