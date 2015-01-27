require 'roda/component/location'

module Browser
  # {Window} instances are {Native} objects used to wrap native window instances.
  #
  # Generally, you will want to use the top level {::Window} instance, which
  # wraps `window` from the main page.
  class Window
    include Native

    # @!attribute [r] history
    # @return [History] the history for this window
    def history
      History.new(`#@native.history`) if `#@native.history`
    end
  end

  # {History} allows manipulation of the session history.
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/API/History
  class History
    include Native

    # @!attribute [r] length
    # @return [Integer] how many items are in the history
    alias_native :length

    # Go back in the history.
    #
    # @param number [Integer] how many items to go back
    def back(number = 1)
      `History.go(-number)`
    end

    # Go forward in the history.
    #
    # @param number [Integer] how many items to go forward
    def forward(number = 1)
      `History.go(number)`
    end

    # Push an item in the history.
    #
    # @param item [String] the item to push in the history
    # @param data [Object] additional state to push
    def push(item, data = nil)
      data = `null` if data.nil?

      `History.pushState(jQuery.parseJSON(data.$to_json()), null, item)`
    end

    # Replace the current history item with another.
    #
    # @param item [String] the item to replace with
    # @param data [Object] additional state to replace
    def replace(item, data = nil)
      data = `null` if data.nil?

      `History.replaceState(data, null, item)`
    end

    def get_state
      Native(`History.getState()`)
    end

    # @!attribute [r] current
    # @return [String] the current item
    def current
      $window.location.path
    end

    def change &block
      %x{
        History.Adapter.bind(window,'statechange',function(e){
          var state = History.getState();
          state = #{Native(`state`)}
          return #{block.call(`state`)}
        });
      }
    end
  end
end
