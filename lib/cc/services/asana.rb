class CC::Service::Asana < CC::Service
  class Config < CC::Service::Config
    attribute :personal_access_token, Axiom::Types::Token, label: "Personal Access Token"
    attribute :api_key, Axiom::Types::Token, label: "API key (Deprecated)"

    attribute :workspace_id, Axiom::Types::String, label: "Workspace ID"

    attribute :project_id, Axiom::Types::String, label: "Project ID",
      description: "(optional)"

    attribute :assignee, Axiom::Types::String, label: "Assignee",
      description: "Assignee email address (optional)"

    validate :authorization_provided
    validates :workspace_id, presence: true

    def authorization_provided
      if api_key.blank? && personal_access_token.blank?
        errors.add(:personal_access_token, "can't be blank")
      end
    end
  end

  ENDPOINT = "https://app.asana.com/api/1.0/tasks".freeze

  self.title = "Asana"
  self.description = "Create tasks in Asana"
  self.issue_tracker = true

  def receive_test
    result = create_task("Test task from Code Climate")
    result.merge(
      message: "Ticket <a href='#{result[:url]}'>#{result[:id]}</a> created.",
    )
  rescue CC::Service::HTTPError => ex
    body = JSON.parse(ex.response_body)
    ex.user_message = body["errors"].map { |e| e["message"] }.join(" ")
    raise ex
  end

  def receive_issue
    title = %(Fix "#{issue["check_name"]}" issue in #{constant_name})

    body = [issue["description"], details_url].join("\n\n")

    create_task(title, body)
  end

  def receive_quality
    create_task("#{quality_title} - #{details_url}")
  end

  def receive_vulnerability
    formatter = CC::Formatters::TicketFormatter.new(self)
    title = formatter.format_vulnerability_title

    create_task("#{title} - #{details_url}")
  end

  private

  def create_task(name, notes = "")
    params = generate_params(name, notes)
    authenticate_http
    http.headers["Content-Type"] = "application/json"
    service_post(ENDPOINT, params.to_json) do |response|
      body = JSON.parse(response.body)
      id = body["data"]["id"]
      url = "https://app.asana.com/0/#{config.workspace_id}/#{id}"
      { id: id, url: url }
    end
  end

  def generate_params(name, notes = nil)
    params = {
      data: { workspace: config.workspace_id, name: name, notes: notes },
    }

    if config.project_id.present?
      # Note this is undocumented, found via trial & error
      params[:data][:projects] = [config.project_id]
    end

    if config.assignee.present?
      params[:data][:assignee] = config.assignee
    end

    params
  end

  def authenticate_http
    if config.personal_access_token.present?
      http.headers["Authorization"] = "Bearer #{config.personal_access_token}"
    else
      http.basic_auth(config.api_key, "")
    end
  end
end
