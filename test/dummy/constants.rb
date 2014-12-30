ENV.fetch('LC_ALL') {'en_US.utf8'}.freeze
RACK_ENV   = ENV.fetch('RACK_ENV') { 'test' }.freeze
DUMMY_PATH = "#{Dir.pwd}/" << (RACK_ENV == 'test' ? 'test/dummy/components' : 'components').freeze
