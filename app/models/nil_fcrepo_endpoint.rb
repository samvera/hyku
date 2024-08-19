# frozen_string_literal: true

class NilFcrepoEndpoint < NilEndpoint
  def switch!
    ActiveFedora::Fedora.register(options)
  end

  def url
    'Fcrepo not initialized'
  end

  def base_path
    'Fcrepo not initialized'
  end

  private

  def options
    { url: 'http://127.0.0.1:99999/nil_fcrepo_endpoint' }
  end
end
