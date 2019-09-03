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
  payload = {
    "data" => {
      "submission_id" => submission_id,
      "status" => status,
      "points" => points,
      "time" => time || 0,
      "memory" => memory || 0,
      "graded_at" => graded_at
    }
  }

  token = get_token
  #puts "TOKEN #{token}"
  #puts "Payload: #{payload.to_json}"
  response = Faraday.post("#{base_url}/updateSubmissionStatus?auth=${token}",
                          payload.to_json,
                          {'Content-Type' => 'application/json'})
  puts response.body
end
