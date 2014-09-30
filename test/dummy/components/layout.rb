class LayoutComp < Roda::Component
  name :layout
  html './test/dummy/public/index.html'

  def display data, &block
    dom.find('body').html yield
    dom
  end
end
