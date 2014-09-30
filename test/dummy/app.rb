class TestApp < Roda
  plugin :component, {
    path: './test/dummy/components'
  }

  route do |r|
    r.components

    r.on 'app' do
      'working'
    end

    r.root do
      component(:layout) do
        'Hello, World!'
      end
    end
  end

  Dir["./test/dummy/components/*.rb"].each { |file| require file }
end
