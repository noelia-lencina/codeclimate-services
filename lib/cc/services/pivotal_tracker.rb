class CC::Service::PivotalTracker < CC::Service
  class Config < CC::Service::Config
    attribute :api_token, String
    attribute :project_id, String
    attribute :labels, String

    validates :api_token, presence: true
    validates :project_id, presence: true
  end

  BASE_URL = "https://www.pivotaltracker.com/services/v3"

  def receive_unit
    params = {
      "story[name]"           => "name",
      "story[story_type]"     => "chore",
      "story[description]"    => "description"
    }

    if config.labels.present?
      params["story[labels]"] = config.labels.strip
    end

    http.headers["X-TrackerToken"] = config.api_token
    url = "#{BASE_URL}/projects/#{config.project_id}/stories"
    resp = http_post(url, params)

    if resp.status == 200
      parse_story(resp)
    end
  end

private

  def parse_story(resp)
    body = Nokogiri::XML(resp.body)

    {
      id:   (body / "story/id").text,
      url:  (body / "story/url").text
    }
  end

end
