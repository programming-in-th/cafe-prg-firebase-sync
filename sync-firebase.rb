#!/usr/bin/env ruby

require 'faraday'
require 'json'

require_relative 'prg_api'

BOT_USER = 'test1'
BASE_URL = 'https://asia-east2-grader-ef0b5.cloudfunctions.net'
LIMIT = 10
SLEEP_TIME = 5

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

  if !LANGUAGE_NAMES[res['language']]
    res['language'] = 'c_cpp'
  end
    
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

  return submission
end

def sync_loop(user, submission_statuses)
  response = call_api_get_oldest_submissions_in_queue(BASE_URL)
  if response.status != 200
    puts 'Request error'
  else
    results = JSON.parse(response.body)['result']
    results.each do |res|
      next if !(res.has_key? 'submission_id')
      
      submission_id = res['submission_id']

      if !submission_statuses.has_key? submission_id
        sub = create_submission(res, user)
        puts "created #{submission_id}"

        submission_statuses[submission_id] = {
          status: :created,
          sub_id: sub.id
        }
      end
    end
  end

  submission_statuses.each do |submission_id, data|
    if data[:status] == :created
      submission = Submission.find(data[:sub_id])
      if submission and submission.graded_at
        puts "#{submission_id} - graded: #{submission.grader_comment}"
        submission_statuses[submission_id][:status] = :graded

        call_api_update_submission_status(BASE_URL,
                                          submission_id,
                                          submission.grader_comment,
                                          submission.points,
                                          submission.max_runtime,
                                          submission.peak_memory,
                                          submission.graded_at)
      end
    end
  end
end

def main
  user = User.find_by login: BOT_USER
  submission_statuses = {}

  while true
    sync_loop(user, submission_statuses)
    sleep(SLEEP_TIME)
  end
end

main
