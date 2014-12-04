require 'tilt'
require 'roda'
require 'roda/component'

RACK_ENV   = ENV.fetch('RACK_ENV') { 'test' }
DUMMY_PATH = "#{Dir.pwd}/" << (RACK_ENV == 'test' ? 'test/dummy/components' : 'components')

class TestApp < Roda
  path = DUMMY_PATH

  plugin :component, { path: path }
  plugin :assets, {
    path: "#{path}/../public",
    css_dir: '',
    css: [
      'css/bootstrap.min.css',
      'css/freelancer.css',
      'font-awesome-4.1.0/css/font-awesome.min.css'
    ],
    js: [ 'jquery.js' ]
  }

  route do |r|
    r.on('img') do
      r.run Rack::Directory.new("#{path}/../public/img")
    end

    r.on('assets/font-awesome-4.1.0/fonts') do
      r.run Rack::Directory.new("#{path}/../public/font-awesome-4.1.0/fonts")
    end

    r.components
    r.assets

    r.on('theme') { component(:theme) }

    r.root do
      component(:layout) do
        'Hello, World!'
      end
    end
  end
end

Dir["#{DUMMY_PATH}/**/*.rb"].sort.each { |file| require file }

