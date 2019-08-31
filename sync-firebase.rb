#!/usr/bin/env ruby

require 'faraday'
require 'json'

BOT_USER = 'test1'
URL = 'https://asia-east2-grader-ef0b5.cloudfunctions.net/getOldestSubmissionsInQueue'
LIMIT = 10

def make_submission(res)
  puts res
end

def main
  response = Faraday.post(URL,
                          "{\"data\":{\"limit\":#{LIMIT}}}",
                          {'Content-Type' => 'application/json'})
  if response.status != 200
    puts 'Request error'
  else
    results = JSON.parse(response.body)['result']
    results.each do |res|
      make_submission(res)
    end
  end
end

main
