# frozen_string_literal: true
require_relative 'custom_test_base'

class AliveTest < CustomTestBase

  def self.id58_prefix
    'd5a'
  end

  # - - - - - - - - - - - - - - - - -

  test 'e5K',
  %w( its alive! ) do
    get '/alive'
    assert last_response.ok?
    assert_equal '{"alive?":true}', last_response.body
  end

end
