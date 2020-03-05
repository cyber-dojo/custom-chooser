# frozen_string_literal: true
require_relative 'http_json_hash/service'

class ExternalCreator

  def initialize(http)
    @http = HttpJsonHash::service(self.class.name, http, 'creator', 4523)
  end

  def ready?
    @http.get(__method__, {})
  end

  def create_custom_group(display_names)
    @http.post(__method__, { display_names:display_names })
  end

  def create_custom_kata(display_name)
    @http.post(__method__, { display_name:display_name })
  end

end
