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
  puts "<li>"
  puts "#{item[:name]} - #{item[:qty]} units"
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
