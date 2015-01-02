class LayoutComp < Roda::Component
  name :layout
  html "../public/AdminLTE-master/index.html"
  setup do |dom|
    dom.at_css('head').add_child assets(:css)
    dom.at_css('body').add_child assets(:js)
    dom.at_css('html').add_child <<-EOF
      <script type="text/javascript" src="/assets/components"></script>
      <script type="text/javascript" src="/faye/client.js"></script>
    EOF

  end

  def display data, &block
    if server?
      # we need this so that roda-components can authenticate your sessions
      dom.at_css('head').add_child csrf_metatag

      dom.find('body').html(yield)

      dom
    end
  end
end
