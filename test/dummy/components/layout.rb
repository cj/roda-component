class LayoutComp < Roda::Component
  name :layout
  html "../public/index.html"

  def display data, &block
    if server?
      dom.find('body').html(yield)

      dom.at_css('head').add_child assets(:css)
      dom.at_css('body').add_child assets(:js)
      dom.at_css('body').add_child <<-EOF
        <script type="text/javascript" src="/assets/components"></script>
        <script type="text/javascript" src="/faye/client.js"></script>
      EOF

      dom
    end
  end
end
