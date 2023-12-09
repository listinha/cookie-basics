#!/usr/bin/env ruby
require 'time'
require 'cgi'

http_path = ENV['HTTP_PATH']
identified_person_name = 'Anonymous'

if File.exist?('database.txt')
  identified_person_name = File.read('database.txt')
end

if http_path == '/identify_user'
  request_payload = ENV['HTTP_PAYLOAD']
  hash_payload = request_payload.split('&').map { |x| k, v = x.split('=', 2); [CGI.unescape(k), CGI.unescape(v)] }.to_h

  identified_person_name = hash_payload['person_name']

  File.write('database.txt', identified_person_name)
end

cookies = {}
cookie_string = ENV['HTTP_COOKIE']
if cookie_string
  cookies = cookie_string.split(';').to_h{ |x| key, value = x.split('=', 2).map(&:strip) }
end

def is_favorite?(item, cookies)
  item[:name] == cookies['favorite_item']
end

items_for_sale = [
  { name: 'Book', qty: 4 },
  { name: 'Wooden house', qty: 2 },
  { name: 'Paper', qty: 200 },
]

secret_items = [
  { name: 'Magic wand', qty: 9 },
  { name: 'Magic potion', qty: 2 },
]

if http_path == '/include_magic_items'
  items_for_sale += secret_items
end

puts "<!doctype html>"
puts "<html>"

puts "<head>"
puts "<title>My First Web Page!</title>"
puts "</head>"

puts "<body>"

puts "<h1>Hello #{identified_person_name}!</h1>"

if http_path == '/include_magic_items'
  puts '<a href="/">No magic</a>'
else
  puts '<a href="/include_magic_items">See magic items</a>'
end

puts "<p>Requesting page #{http_path}</p>"
puts "<p>#{Time.now}</p>"

puts "<ul>"
items_for_sale.each do |item|
  favorite_str = if is_favorite?(item, cookies)
    " - 💙"
  else
    " - 🫥 (<a href=\"/set_favorite?fav=#{item[:name]}\">set</a>)"
  end

  puts "<li>"
  puts "#{item[:name]} - #{item[:qty]} units#{favorite_str}"
  puts "</li>"
end
puts "</ul>"

puts '<img width="200" src="/book_image.jpg">'

puts '<form method="POST" action="/identify_user">'
puts '<p>Name: <input type="text" name="person_name" value=""></p>'
puts '<p><input type="submit" value="Send!" name="submit"></p>'
puts '</form>'

puts "</body>"

puts "</html>"
