#!/usr/bin/env ruby

require 'faraday'
require 'json'

require_relative 'prg_api'
require_relative 'sync_config'

FALLBACK_PROBLEM_NAME = 'nonexistance'
FALLBACK_LANGUAGE = 'cpp'

# judge/rails initialization
GRADER_ENV = 'grading'
require File.join(File.dirname(__FILE__),'config/environment')
RAILS_ENV = 'development'
require RAILS_ROOT + '/config/environment'

def create_submission(res, user)
  problem_name = res['problem_id']
  problem = Problem.find_by name: problem_name
  language = Language.find_by name: res['language']
  
  if !problem
    problem = Problem.find_by name: FALLBACK_PROBLEM_NAME
  end

  if !language
    language = Language.find_by name: FALLBACK_LANGUAGE
  end

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
  if !response or response.status != 200
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
                                          FIREBASE_CREDENTIAL_FILE,
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
