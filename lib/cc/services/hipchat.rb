class CC::Service::HipChat < CC::Service
  BASE_URL = "https://api.hipchat.com/v1"

  def receive_coverage
    details = {
      coverage: payload["coverage"]
    }

    payload = {
      from:       "Code Climate",
      message:    render_coverage(details),
      auth_token: required_config_value(:auth_token),
      room_id:    required_config_value(:room_id),
      notify:     false,
      color:      "yellow"
    }

    http_post("#{BASE_URL}/rooms/message", payload)
  end

  def render_coverage(details)
    Liquid::Template.parse(<<-EOF.strip).render(details.stringify_keys)
      <b>Coverage:</b> {{coverage}}
    EOF
  end

end
