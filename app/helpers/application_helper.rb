module ApplicationHelper
  # for testing only, you can use it like this:
  # <p <%= tag.attributes(test_id("the-thing-for-test-id")) %>>...</p>
  def test_id(value)
    {"data-test-id" => value} unless Rails.env.production?
  end
end
