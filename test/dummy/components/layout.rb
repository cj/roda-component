class LayoutComp < Roda::Component
  name :layout
  html './test/dummy/public/index.html'

  def display data, &block
    if server?
      dom.find('body').html(yield)
      dom
    end
  end
end
