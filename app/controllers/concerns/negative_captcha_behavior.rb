# frozen_string_literal: true

module NegativeCaptchaBehavior
  private

  def negative_captcha_for(fields)
    NegativeCaptcha.new(
      secret: ENV.fetch('NEGATIVE_CAPTCHA_SECRET', 'default-value-change-me'),
      spinner: request.remote_ip,
      fields:,
      css: 'display: none',
      params:
    )
  end
end
