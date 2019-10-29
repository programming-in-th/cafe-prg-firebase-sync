def call_api_get_oldest_submissions_in_queue(base_url)
  begin
    Faraday.post("#{base_url}/getOldestSubmissionsInQueue",
                 "{\"data\":{\"limit\":#{LIMIT}}}",
                 {'Content-Type' => 'application/json'})
  rescue
    return nil
  end
end

def call_api_update_submission_status(base_url,
                                      credential_filename,
                                      submission_id,
                                      status,
                                      points,
                                      time,
                                      memory,
                                      graded_at)
  time ||= 0
  memory ||= 0

  cmd = "python update_submission.py #{credential_filename} #{submission_id} \"#{status}\" #{points} #{time} #{memory} \"#{graded_at}\""
  puts(cmd)
  system(cmd)
end
