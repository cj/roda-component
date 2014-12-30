unless defined? RACK_ENV
  ENV.fetch('LC_ALL') {'en_US.utf8'}.freeze
  RACK_ENV   = ENV.fetch('RACK_ENV') { 'test' }.freeze
  DUMMY_PATH = "#{Dir.pwd}/" << (RACK_ENV == 'test' ? 'test/dummy/components' : 'components').freeze
end

require 'tilt'
require 'roda'
require 'nokogiri'
require 'roda/component'

class TestApp < Roda
  path = DUMMY_PATH

  plugin :component, { path: path }
  plugin :assets, {
    path: "#{path}/../public/AdminLTE-master",
    css_dir: '',
    # css: [ 'css/AdminLTE.css'],
    # js: [ 'jquery.js' ]
  }

  route do |r|
    r.components
    r.assets

    %w(js css img).each do |type|
      r.on(type) { r.run Rack::Directory.new("#{path}/../public/AdminLTE-master/#{type}") }
    end

    r.on('assets') { r.run Rack::Directory.new("#{path}/../public/AdminLTE-master") }

    r.on('assets/font-awesome-4.1.0/fonts') do
      r.run Rack::Directory.new("#{path}/../public/AdminLTE-master/font-awesome-4.1.0/fonts")
    end

    r.root { component(:theme) }
  end
end

Dir["#{DUMMY_PATH}/**/*.rb"].sort.each { |file| require file }

