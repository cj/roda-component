require_relative 'helper'

scope 'component' do
  test 'app' do
    assert body('/app')['working']
  end

  test 'render' do
    assert body('/')['head']
  end
end
