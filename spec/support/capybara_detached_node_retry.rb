# frozen_string_literal: true

# chromedriver sometimes raises this as an UnknownError instead of a retryable
# StaleElementReferenceError, so Capybara's synchronize never catches it.
module Hyku
  module Specs
    module RetriesDetachedNodeErrors
      DETACHED_NODE_ERROR = /node with given id does not belong to the document/i

      protected

      def catch_error?(error, errors = nil)
        return true if error.is_a?(Selenium::WebDriver::Error::WebDriverError) &&
                       error.message.to_s.match?(DETACHED_NODE_ERROR)

        super
      end
    end
  end
end

Capybara::Node::Base.prepend(Hyku::Specs::RetriesDetachedNodeErrors)
