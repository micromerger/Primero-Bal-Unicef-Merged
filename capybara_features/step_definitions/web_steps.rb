# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all capybara_features/**/*.rb
# files.

require 'uri'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))

module WithinHelpers
  def with_scope(locator)
    locator ? within(:css, locator) { yield } : yield
  end
end
World(WithinHelpers)

Then /^(?:|I )should have a "(.*)" link which will lead me to the "(.*)" page$/ do |link, page_name|
  page.should have_content(link)
  click_link(link)
  expect(page).to have_title(page_name)
end

When /^I see the header$/ do
  page.should have_css('header')
  page.should have_content('Logout')
  page.should have_content('My Account')
  page.should have_content('Contact & Help')
end

#////////////////////////////////////////////////////////////////
#//  Pre-Existing Steps
#////////////////////////////////////////////////////////////////

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )press "([^\"]*)"(?: within "([^\"]*)")?$/ do |button, selector|
  with_scope(selector) do
    click_button(button)
  end
end

When /^I search$/ do
  find("//input[@value='Search']").click
end

When /^(?:|I )(?:can )?follow "([^\"]*)"(?: within "([^\"]*)")?$/ do |link, selector|
  with_scope(selector) do
    click_link(link)
  end
end

When /^(?:|I )(?:can )?click "([^\"]*)"(?: within "([^\"]*)")?$/ do |selector, within|
  with_scope(within) do
    Page.find(selector).click
  end
end

When /^I follow "(.+)" span$/ do |locator|
  find(:xpath, "//span[text()='#{locator}']").click
end

When /^I cannot follow "([^\"]*)"(?: within "([^\"]*)")?$/ do |link, selector|
  exception=nil
  begin
    with_scope(selector) do
      click_link(link)
    end
  rescue Exception=>e
    exception=e
  end
  exception.should_not be_nil
  exception.class.should==Capybara::ElementNotFound
end

When /^(?:|I )fill in "([^\"]*)" with "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, value, selector|
  with_scope(selector) do
    fill_in(field, :visible => true, :with => value)
  end
end

When /^(?:|I ) select "([^\"]*)" for "([^\"]*)"$/ do |value, field|
  page.execute_script "$('#{field}').trigger('focus')"
  page.execute_script "$('a.ui-datepicker-next').trigger('click')"
  page.execute_script "$(\"a.ui-state-default:contains('15')\").trigger(\"click\")"
end

# TODO: Add support for checkbox, select og option
# based on naming conventions.
#
When /^(?:|I )fill in the following(?: within "([^\"]*)")?:$/ do |selector, fields|
  with_scope(selector) do
    fields.rows_hash.each do |name, value|
      step %{I fill in "#{name}" with "#{value}"}
    end
  end
end

When /^(?:|I )select "([^\"]*)" from "([^\"]*)"(?: within "([^\"]*)")?$/ do |value, field, selector|
  with_scope(selector) do
    select(value, :from => field, :visible => true)
  end
end

When /^(?:|I )(?:can )?check "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, selector|
  with_scope(selector) do
    check(field)
  end
end

When /^(?:|I )uncheck "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, selector|
  with_scope(selector) do
    uncheck(field)
  end
end

When /^(?:|I )(?:can )?choose "([^\"]*)"(?: within "([^\"]*)")?$/ do |field, selector|
  with_scope(selector) do
    choose(field)
  end
end

When /^(?:|I )attach the file "([^\"]*)" to "([^\"]*)"(?: within "([^\"]*)")?$/ do |path, field, selector|
  with_scope(selector) do
    path = "#{Rails.root}/#{path}"
    attach_file(field, path)
  end
end

Then /^(?:|I )should see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)
  if defined?(Spec::Rails::Matchers)
    page.should have_content(regexp)
  else
    page.text.should match(regexp)
  end
end

Then /^(?:|I )should see "([^\"]*)"(?: within "([^\"]*)")?$/ do |text, selector|
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      page.should have_content(text)
    else
      assert page.has_content?(text)
    end
  end
end

Then /^(?:|I )should not see "([^\"]*)"(?: within "([^\"]*)")?$/ do |text, selector|
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      page.should have_no_content(text)
    else
      assert page.has_no_content?(text)
    end
  end
end

Then /^(?:|I )should not see \/([^\/]*)\/(?: within "([^\"]*)")?$/ do |regexp, selector|
  regexp = Regexp.new(regexp)
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      page.should have_no_xpath('//*', :text => regexp)
    else
      assert page.has_no_xpath?('//*', :text => regexp)
    end
  end
end

Then /^the "([^\"]*)" field(?: within "([^\"]*)")? should contain "([^\"]*)"$/ do |field, selector, value|
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      find_field(field).value.should =~ /#{value}/
    else
      assert_match(/#{value}/, field_labeled(field).value)
    end
  end
end

Then /^the "([^\"]*)" field(?: within "([^\"]*)")? should not contain "([^\"]*)"$/ do |field, selector, value|
  with_scope(selector) do
    if defined?(Spec::Rails::Matchers)
      find_field(field).value.should_not =~ /#{value}/
    else
      assert_no_match(/#{value}/, find_field(field).value)
    end
  end
end

Then /^the "([^"]*)" radio-button(?: within "([^"]*)")? should be checked$/ do |label, selector|
  with_scope(selector) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      ["true", "checked", true].should include field_checked
    else
      field_checked
    end
  end
end

Then /^the "([^"]*)" radio-button(?: within "([^"]*)")? should not be checked$/ do |label, selector|
  with_scope(selector) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      field_checked.should == nil
    else
      !field_checked
    end
  end
end

Then /^the "([^"]*)" checkbox(?: within "([^"]*)")? should be checked$/ do |label, selector|
  with_scope(selector) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      ["true", true].should include field_checked
    else
      field_checked
    end
  end
end

Then /^the "([^"]*)" checkbox(?: within "([^"]*)")? should not be checked$/ do |label, selector|
  with_scope(selector) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      [nil, false].should include field_checked
    else
      !field_checked
    end
  end
end

Then /^(?:|I )should be on (.+)$/ do |page_name|
  if defined?(Spec::Rails::Matchers)
    URI.parse(current_url).path.should == path_to(page_name)
  else
    assert_equal path_to(page_name), URI.parse(current_url).path
  end
end

Then /^(?:|I )should have the following query string:$/ do |expected_pairs|
  actual_params   = CGI.parse(URI.parse(current_url).query)
  expected_params = Hash[expected_pairs.rows_hash.map{|k,v| [k,[v]]}]

  if defined?(Spec::Rails::Matchers)
    actual_params.should == expected_params
  else
    assert_equal expected_params, actual_params
  end
end

Then /^show me the page$/ do
  save_and_open_page
end

When /^I fill in a (\d+) character long string for "([^"]*)"$/ do |length, field|
  fill_in field, :with=>("x" * length.to_i)
end

Then /^I should see the order (.+)$/ do |input|
  current = 0
  input.split(',').each do |match|
    index = page.body.index(match)
    assert index > current, "The index of #{match} was not greater than #{current}"
    current = index
  end
end

Then /^(.+) button is disabled$/ do |text|
  assert !find_button(text).visible?
end

When /^(?:|I )select "([^\"]*)"(?: within "([^\"]*)")? for language change$/ do |button, selector|
  with_scope(selector) do
    find("//input[@class='btn_submit']").click
  end
end


And /^I submit the form$/ do
  click_button('Save')
end

When /^I clear the search results$/ do
  click_button("reset")
end

Then /^I should see first (\d+) records in the search results$/ do |arg1|
  assert page.has_content?("Displaying children 1 - 20 ")
end

When /^I goto the "(.*?)"$/ do |text|
  find(:xpath,"//a[@class='"+text+"']").click
end


Then /^I should see next records in the search results$/ do
  assert page.has_content?("Displaying children 21 - 25 ")
end

Then /^I should see link to "(.*?)"$/ do |text|
  page.should have_xpath("//span[@class='"+text+"']")
end

Then /^I should( not)? be able to view the tab (.+)$/ do|not_visible,tab_name|
  tab_element = page.has_xpath?("//div[@class='main_bar']//ul/li/a[text()='"+tab_name+"']")
  tab_element.should == !not_visible
end

When /^(?:|I )select "([^\"]*)"(?: within "([^\"]*)")?$/ do |button, selector|
  with_scope(selector) do
    find("//input[@class='btn_submit']").click
  end
end

When /^I go and press "([^"]*)"$/ do |arg|
  find("//input[@class='btn_submit']").click
end

Then /^"([^"]*)" option should be unavailable to me$/ do |element|
  page.should have_no_xpath("//span[@class='"+element+"']")
end

Then /^password prompt should be enabled$/ do
  assert page.has_content?("Password")
end

When /^I fill in "([^"]*)" in the password prompt$/ do |arg|
  fill_in 'password-prompt-dialog', :with => 'abcd'
end

Then /^Error message should be displayed$/ do
  assert page.has_content?("Enter a valid password")
end

When /^I follow "([^"]*)" for child records$/ do |arg|
  find(:xpath, "//span[@class='export']").click
end

Then /^the message "([^"]*)" should be displayed to me$/ do |text|
  assert page.has_content?("#{text}")
end

Then /^I should be redirected to "([^"]*)" Page$/ do |page_name|
  assert page.has_content?("#{page_name}")
end

When /^I select the "([^"]*)"$/ do |element|
  find("//div[@class='"+element+"']").click
end

When /^I can download the "([^"]*)"$/ do |item|
  find("//a[@id='"+item+"']").click
end

When /^I click OK in the browser popup$/ do
  page.driver.browser.switch_to.alert.accept
end

When /^I click Cancel in the browser popup$/ do
  page.driver.browser.switch_to.alert.dismiss
end

#Chosen with the values to select in the table.
When /^I choose from "([^\"]*)":$/ do |chosen, table |
  label = find("//label[text()='#{chosen}']", :visible => true)
  chosen_id = label["for"] + "__chosen"
  chosen = find(:xpath, "//div[@id='#{chosen_id}']", :visible => true)
  table.raw.flatten.each do |option|
    #This make visible the options to choose.
    chosen.click
    chosen.find(:xpath, "./div[@class='chosen-drop']//ul[@class='chosen-results']//li[text()='#{option}']").click
    #To select another items, it is needed the chosen lost the focus to make click again
    #to make visible the items to select.
    label.click
  end
end

#Chosen to select the values one by one, this is useful in subforms because we can't send the table from the string.
When /^I choose option "([^\"]*)" from "([^\"]*)"(?: within "([^"]*)")?$/ do |option, chosen, selector |
  selector ||= ""
  label = find("#{selector}//label[text()='#{chosen}']")
  chosen_id = label["for"] + "__chosen"
  chosen = find(:xpath, "//div[@id='#{chosen_id}']")
  #This make visible the options to choose.
  chosen.click
  chosen.find(:xpath, "./div[@class='chosen-drop']//ul[@class='chosen-results']//li[text()='#{option}']").click
  #To select another items, it is needed the chosen lost the focus to make click again
  #to make visible the items to select.
  label.click
end

#Chosen with the values to select in the table.
When /^the chosen "([^\"]*)" should have the following values:$/ do |chosen, table |
  label = find("//label[text()='#{chosen}']", :visible => true)
  chosen_select_id = label["for"] + "_"
  chosen_select = find(:xpath, "//select[@id='#{chosen_select_id}']", :visible => false)
  table.raw.flatten.each do |option|
    chosen_select.value.include?(option).should eq(true)
  end
end

When /^the chosen "([^\"]*)" should not have any selected value$/ do |chosen|
  label = find("//label[text()='#{chosen}']", :visible => true)
  chosen_select_id = label["for"] + "_"
  chosen_select = find(:xpath, "//select[@id='#{chosen_select_id}']", :visible => false)
  chosen_select.value.blank?.should be true
end