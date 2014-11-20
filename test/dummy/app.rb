require 'tilt'
require 'roda'
require 'roda/component'

RACK_ENV   = ENV.fetch('RACK_ENV') { 'test' }
DUMMY_PATH = "#{Dir.pwd}/" << (RACK_ENV == 'test' ? 'test/dummy/components' : 'components')

class TestApp < Roda
  path = DUMMY_PATH

  plugin :component, { path: path }

  route do |r|
    r.components

    r.on 'assets/jquery.js' do
      response.headers["Content-Type"] = 'application/javascript; charset=UTF-8'
      File.read "#{path}/../public/jquery.js"
    end

    r.on('box') { component(:box) }

    r.root do
      component(:layout) do
        'Hello, World!'
      end
    end
  end
end

Dir["#{DUMMY_PATH}/**/*.rb"].sort.each { |file| require file }

