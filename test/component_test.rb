require_relative 'helper'

setup do
  # This is just here to make sure opal compile works
  # env = Opal::Environment.new
  # env.append_path "./lib"
  # env.append_path "./test/dummy/components"
  # js = ''
  # js << env["roda/component"].to_s
  # js << env["layout"].to_s
end

scope 'component' do
  test 'app' do
    assert body('/app')['working']
  end

  test 'render' do
    assert body('/')['head']
  end
end
