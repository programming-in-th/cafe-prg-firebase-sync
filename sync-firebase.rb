#!/usr/bin/env ruby

require 'faraday'
require 'json'

BOT_USER = 'test1'
URL = 'https://asia-east2-grader-ef0b5.cloudfunctions.net/getOldestSubmissionsInQueue'
LIMIT = 10
SLEEP_TIME = 60

LANGUAGE_NAMES = {
  'c_cpp' => 'cpp',
  'python' => 'python'
}

# judge/rails initialization
GRADER_ENV = 'grading'
require File.join(File.dirname(__FILE__),'config/environment')
RAILS_ENV = 'development'
require RAILS_ROOT + '/config/environment'

def create_submission(res, user)
  problem_name = res['problem_id']
  problem = Problem.find_by name: problem_name
  language = Language.find_by name: LANGUAGE_NAMES[res['language']]

  submission = Submission.new
  submission.language = language
  submission.problem = problem
  submission.user = user
  submission.source = res['code']
  submission.source.encode!('UTF-8', 'UTF-8', invalid: :replace, replace: '')

  submission.submitted_at = Time.new.gmtime
  submission.save!

  Task.create(submission: submission,
              status: Task::STATUS_INQUEUE)
end

def main
  user = User.find_by login: BOT_USER
    
  response = Faraday.post(URL,
                          "{\"data\":{\"limit\":#{LIMIT}}}",
                          {'Content-Type' => 'application/json'})
  if response.status != 200
    puts 'Request error'
  else
    results = JSON.parse(response.body)['result']
    results.each do |res|
      create_submission(res, user)
    end
  end
end

main
