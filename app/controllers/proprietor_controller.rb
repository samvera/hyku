# frozen_string_literal: true

class ProprietorController < ApplicationController
  skip_before_action :require_active_account!
  layout "proprietor"
end
