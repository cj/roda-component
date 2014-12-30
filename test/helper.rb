lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative 'dummy/app'

require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    phantomjs: ENV['PHANTOMJS_PATH'] || '/bin/phantomjs'
  })
end

Capybara.app = TestApp

# use port 8080 if it's open
unless system("lsof -i:8080", out: '/dev/null')
  Capybara.server_port = 8080
end
Capybara.default_driver    = :poltergeist
Capybara.javascript_driver = :poltergeist
