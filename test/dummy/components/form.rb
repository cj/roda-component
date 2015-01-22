require_relative 'forms/form'

class Form < Roda::Component
  comp_name :form
  comp_html "../public/form/index.html"
  comp_setup do |dom|
    # remove hard coded links as we are adding them in using the assets plugin.
    dom.css('head > link').remove
    # add require css and javascript
    dom.at_css('head').add_child assets([:css, :form])
    dom.at_css('html').add_child assets([:js, :form])
    dom.at_css('html').add_child <<-EOF
      <script type="text/javascript" src="/assets/components/roda/component.js"></script>
      <script type="text/javascript" src="/faye/client.js"></script>
    EOF
  end

  def display
    return unless server?

    dom.at_css('head').add_child csrf_metatag

    form = Forms::Login.new({
      name: 'test',
      address: {
        zip: 90036
      }
    }, key: :user, dom: dom.find('#form'))

    form.render_values

    dom
  end

  on :form, '#form', Forms::Login, key: :user do |form, el, evt|
    if form.valid?
    else
      form.display_errors
    end
  end
end
