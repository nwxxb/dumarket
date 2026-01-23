Capybara.configure do |config|
  config.test_id = "data-test-id"
end

Capybara.add_selector(:test_id) do
  xpath do |locator|
    XPath.descendant[XPath.attr(Capybara.test_id) == locator]
  end
end
