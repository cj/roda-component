require_relative 'helper'

class ComponentTest < PryTest::Test
  before { @app = App.new(self) }

  test 'app' do
    assert @app.body('/app')['working']
  end

  test 'render' do
    assert @app.body('/')['head']
  end
end
