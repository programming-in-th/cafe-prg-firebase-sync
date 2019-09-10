def get_token
  return `python get_token.py`.chomp
end

def call_api_get_oldest_submissions_in_queue(base_url)
  Faraday.post("#{base_url}/getOldestSubmissionsInQueue",
               "{\"data\":{\"limit\":#{LIMIT}}}",
               {'Content-Type' => 'application/json'})
end

def call_api_update_submission_status(base_url,
                                      submission_id,
                                      status,
                                      points,
                                      time,
                                      memory,
                                      graded_at)
  time ||= 0
  memory ||= 0

  cmd = "python update_submission.py #{submission_id} \"#{status}\" #{points} #{time} #{memory} \"#{graded_at}\""
  puts(cmd)
  system(cmd)
end
