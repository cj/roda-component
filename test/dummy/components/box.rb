class BoxComponent < Roda::Component
  name :box
  html "../public/index.html"
  setup do |dom|
    tmpl :box, dom.at_css('#show-box .box')
  end

  def display data, &block
    component(:layout) do
      dom.find('body').html
    end if server?
  end

  on :click, -> { dom.find('#show-box a.show') } do |el|
    el.remove
    dom.find('body').append tmpl(:box).html
  end
end
