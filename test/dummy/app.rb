unless defined? RACK_ENV
  ENV.fetch('LC_ALL') {'en_US.utf8'}.freeze
  RACK_ENV   = ENV.fetch('RACK_ENV') { 'test' }.freeze
  DUMMY_PATH = "#{Dir.pwd}/" << (RACK_ENV == 'test' ? 'test/dummy/components' : 'components').freeze
end

require 'sass'
require 'tilt'
require 'roda'
require 'nokogiri'
require 'roda/component'

class TestApp < Roda
  path = DUMMY_PATH

  use Rack::Session::Cookie,
    key:    "test:roda:components",
    secret: "na"

  plugin :csrf, header: 'X-CSRF-TOKEN'
  plugin :component, { path: path }
  plugin :assets, {
    path: "#{path}/../public/chat",
    css_dir: '',
    css: [
      'bower/open-sans-fontface/open-sans.css',
      'bower/font-awesome/css/font-awesome.css',
      'bower/jScrollPane/style/jquery.jscrollpane.css',
      'css/style.css',
      'css/login.scss'
    ],
    js: [
      'bower/jquery/dist/jquery.js',
      'bower/jScrollPane/script/jquery.mousewheel.js',
      'bower/jScrollPane/script/jquery.jscrollpane.js'
    ]
  }

  route do |r|
    r.components
    r.assets

    %w(js css img).each do |type|
      r.on(type) { r.run Rack::Directory.new("#{path}/../public/chat/#{type}") }
    end

    r.on('assets') { r.run Rack::Directory.new("#{path}/../public/chat") }

    r.on('assets/font-awesome-4.1.0/fonts') do
      r.run Rack::Directory.new("#{path}/../public/chat/font-awesome-4.1.0/fonts")
    end

    r.root { component(:chat) }
  end
end

Dir["#{DUMMY_PATH}/**/*.rb"].sort.each { |file| require file }

