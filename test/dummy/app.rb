unless defined? RACK_ENV
  ENV.fetch('LC_ALL') {'en_US.utf8'}.freeze
  RACK_ENV   = ENV.fetch('RACK_ENV') { 'test' }.freeze
  DUMMY_PATH = "#{Dir.pwd}/" << (RACK_ENV == 'test' ? 'test/dummy/components' : 'components').freeze
end

require 'sass'
require 'tilt'
require 'roda'
require 'nokogiri'
require 'shield'
require 'sequel'
require 'roda/component'
require 'binding_of_caller'
require 'better_errors'

# BetterErrors.application_root = __dir__
# BetterErrors::Middleware.allow_ip! "0.0.0.0/0"

class TestApp < Roda
  include Shield::Helpers

  path = DUMMY_PATH

  DB = Sequel.connect('sqlite://dummy.db')

  unless DB.table_exists?(:users)
    DB.create_table :users do
      primary_key :id
      String :first_name
      String :last_name
      String :email
      String :crypted_password
    end
  end

  require_relative 'models/user'

  # use BetterErrors::Middleware
  use Shield::Middleware, "/login"
  use Rack::Session::Cookie,
    key:    "test:roda:component",
    secret: "na"

  plugin :csrf, header: 'X-CSRF-TOKEN', skip: ['POST:/faye']
  plugin :component, { path: 'components', token: '687^*&SAD876asd87as6d*&8asd', debug: true }
  plugin :assets, {
    path: "#{path}/../public",
    css_dir: '',
    js_dir: '',
    group_subdirs: false,
    css: {
      chat: [
        'bower/open-sans-fontface/open-sans.css',
        'bower/font-awesome/css/font-awesome.css',
        'bower/jScrollPane/style/jquery.jscrollpane.css',
        'chat/css/style.css',
        'chat/css/login.scss'
      ],
      form: [
        'form/css/style.css'
      ]
    },
    js: {
      chat: [
        'bower/jquery/dist/jquery.js',
        'bower/jScrollPane/script/jquery.mousewheel.js',
        'chat/bower/jScrollPane/script/jquery.jscrollpane.js'
      ],
      form: [
        'bower/jquery/dist/jquery.js',
        'form/js/index.js'
      ]
    }
  }

  def current_user
    authenticated(Models::User)
  end

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

    r.root { component(:chat, js: true) }

    r.on('form') do
      component(:form, js: true)
    end

    r.on('login')  { component(:login, js: true) }
    r.on('logout') { component(:login, call: :logout) }

    r.on 'session/:key/:value' do |key, value|
      session[key] = value
      response.write '<h3>Added:</h3>'
      response.write "<div><b>#{key}</b>: #{value}</div>"
    end

    r.on 'session/:key' do |key|
      session.delete key
      response.write '<h3>Deleted:</h3>'
      response.write "<div><b>#{key}</b></div>"
    end

    r.on 'session' do
      session.each do |key, value|
        response.write "<div><b>#{key}</b>: #{value}</div>"
      end
      response.write '<br><br><br><br>'

      request.env.each do |key, value|
        response.write "<div><b>#{key}</b>: #{value}</div>"
      end
    end
  end
end

Dir["#{DUMMY_PATH}/**/*.rb"].sort.each { |file| require file }
