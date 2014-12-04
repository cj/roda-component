class BoxComponent < Roda::Component
  name :theme
  html "../public/index.html"
  setup do |dom|
    tmpl :about_title, dom.at_css('#about h2.about-title')
  end

  def display data, &block
    component(:layout) do
      dom.find('body').html
    end if server?
  end

  on :click, '#about a.show-about-title' do |el|
    el.remove
    # todo: automatically use .dom if using things like
    # append/prepend/after/before
    dom.find('#about .col-lg-12').prepend tmpl(:about_title).dom
  end
end
