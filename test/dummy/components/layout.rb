class LayoutComp < Roda::Component
  comp_name :layout
  comp_html "../public/chat/index.html"
  comp_setup do |dom|
    # remove hard coded links as we are adding them in using the assets plugin.
    dom.css('head > link').remove
    # add require css and javascript
    dom.at_css('head').add_child assets(:css)
    dom.at_css('html').add_child assets(:js)
    dom.at_css('html').add_child <<-EOF
      <script type="text/javascript" src="/assets/components"></script>
      <script type="text/javascript" src="/faye/client.js"></script>
    EOF
  end

  def display data, &block
    if server?
      body_class = data.delete :body_class

      # we need this so that roda-components can authenticate your sessions
      dom.at_css('head').add_child csrf_metatag

      dom.find('body').html(yield)

      dom.at('body')['class'] = body_class if body_class

      dom
    end
  end
end
