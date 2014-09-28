class LayoutComp < Roda::Component
  name :layout
  html './test/dummy/public/index.html'

  def default &block
    dom.find('body').html = yield
    dom
  end
end
