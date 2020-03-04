# frozen_string_literal: true
require_relative 'test_base'

class IndexTest < TestBase

  def self.id58_prefix
    'a73'
  end

  # - - - - - - - - - - - - - - - - -

  test '18w', %w(
  |GET/index_group offers all display_names
  |ready to create a group
  ) do
    get '/index_group'
    assert last_response.ok?
    html = last_response.body
    assert heading(html).include?('our'), html
    refute heading(html).include?('my'), html
    display_names.each do |display_name|
      assert html =~ div_for(display_name), display_name
    end
  end

  # - - - - - - - - - - - - - - - - -

  test '19w', %w(
  |GET/index_kata offers all display_names
  |ready to create a kata
  ) do
    get '/index_kata'
    assert last_response.ok?
    html = last_response.body
    assert heading(html).include?('my'), html
    refute heading(html).include?('our'), html
    display_names.each do |display_name|
      assert html =~ div_for(display_name), display_name
    end
  end

  private

  def heading(html)
    # (.*?) for non-greedy match
    # /m for . matching newlines
    html.match(/<div id="heading">(.*?)<\/div>/m)[1]
  end

  def div_for(display_name)
    plain_display_name = Regexp.quote(display_name)
    /<div class="display-name">\s*#{plain_display_name}\s*<\/div>/
  end

end
