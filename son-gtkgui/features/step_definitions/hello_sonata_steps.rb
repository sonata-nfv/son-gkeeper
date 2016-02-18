Then(/^I should see the welcome message$/) do
  expect(page).to have_content("Hello, SONATA End User!!")
end
