# frozen_string_literal: true

## Override BlacklightOaiProvider::ResumptionToken
# Remove when https://github.com/projectblacklight/blacklight_oai_provider/issues/47 is resolved
# Override to fix Date#utc error when building resumption tokens.
# The OAI gem passes from/until as Date objects, but encode_conditions
# calls .utc which only exists on Time. We also need to preserve
# end-of-day semantics for `until` Date values — converting a Date
# to midnight would exclude records created later that day.
module BlacklightOaiProvider
  module ResumptionTokenDecorator
    def encode_conditions
      encoded_token = @prefix.to_s.dup
      encoded_token << ".s(#{set})" if set
      encoded_token << ".f(#{date_to_time(from).utc.xmlschema})" if from
      encoded_token << ".u(#{date_to_time(self.until, end_of_day: true).utc.xmlschema})" if self.until
      encoded_token << ".t(#{total})" if total
      encoded_token << ":#{last}"
    end

    private

    def date_to_time(value, end_of_day: false)
      return value unless value.is_a?(Date) && !value.is_a?(Time)

      if end_of_day
        value.to_time(:utc).end_of_day
      else
        value.to_time(:utc)
      end
    end
  end
end

BlacklightOaiProvider::ResumptionToken.prepend(BlacklightOaiProvider::ResumptionTokenDecorator)
