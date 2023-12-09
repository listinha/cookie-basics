#!/usr/bin/env ruby
require 'socket'
require 'cgi'

server_socket = TCPServer.new('0.0.0.0', 9876)
server_socket.listen(10)

loop do
  client_socket = server_socket.accept

  top_line = client_socket.readline
  http_method, http_path, http_version = top_line.split(' ', 3)
  puts "Client wants '#{http_method}' path '#{http_path}'"

  request_payload_length = 0

  headers = []

  loop do
    header_line = client_socket.readline.chomp
    break if header_line == ""

    header_name, header_value = header_line.split(':', 2)
    header_name = header_name.downcase
    header_value = header_value[1..]

    if header_name == "content-length"
      request_payload_length = Integer(header_value)
    end

    headers << [ header_name, header_value ]

    puts "  #{header_line}"
  end

  request_payload = if request_payload_length == 0
    nil
  else
    client_socket.read(request_payload_length)
  end

  headers.each do |name, value|
    parsed_name = name.upcase.tr('-', '_')
    ENV["HTTP_#{parsed_name}"] = value
  end

  if request_payload
    puts "-- Includes payload: #{request_payload}"
  end

  ENV['HTTP_PAYLOAD'] = request_payload

  if http_path == '/book_image.jpg'
    content = File.read('book_image.jpg')

    client_socket.write("HTTP/1.1 200 OK\r\n")
    client_socket.write("Content-Type: image/jpeg\r\n")
    client_socket.write("Connection: close\r\n")
    client_socket.write("Content-Length: #{content.b.length}\r\n")
    client_socket.write("\r\n")
    client_socket.write(content.b)
  elsif http_path.start_with?('/set_favorite')
    # /set_favorite?fav=Book&age=40&fkjffj
    actual_path, query_string = http_path.split('?', 2)
    query_parameters = query_string.split('&').to_h{ |x| k, v = x.split('=', 2) }

    new_favorite_item = query_parameters['fav']

    puts "THIS DOES WORKS!: #{new_favorite_item}"

    new_favorite_item = CGI.unescape(new_favorite_item)
    puts "Setting cookie: #{new_favorite_item}"

    client_socket.write("HTTP/1.1 302 Temporary\r\n")
    client_socket.write("Location: /\r\n")
    client_socket.write("Set-Cookie: favorite_item=#{new_favorite_item}\r\n")
    # client_socket.write("Set-Cookie: favorite_item=wooden%20house\r\n")
    client_socket.write("Connection: close\r\n")
    client_socket.write("\r\n")
  else
    ENV['HTTP_METHOD'] = http_method
    ENV['HTTP_PATH'] = http_path

    content = `./app.rb`

    headers.each do |name, value|
      parsed_name = name.upcase.tr('-', '_')
      ENV["HTTP_#{parsed_name}"] = nil
    end
    ENV['HTTP_PAYLOAD'] = nil

    client_socket.write("HTTP/1.1 200 OK\r\n")
    client_socket.write("Content-Type: text/html; charset=utf-8\r\n")
    client_socket.write("Connection: close\r\n")
    client_socket.write("Content-Length: #{content.b.length}\r\n")
    client_socket.write("X-Foo-Bar: qux\r\n")
    client_socket.write("\r\n")
    client_socket.write(content.b)
  end


  # client_socket.close
end
