# frozen_string_literal: true

require 'rake'

module RakeHelper
  def run_task(task_name, *args)
    Rake::Task.define_task(:environment)
    capture_stdout_stderr do
      Rake.application[task_name].reenable
      Rake.application[task_name].invoke(*args)
    end
  end

  # saves original $stdout in variable
  # set $stdout as local instance of StringIO
  # yields to code execution
  # returns the local instance of StringIO
  # resets $stdout to original value
  def capture_stdout_stderr
    out = StringIO.new
    err = StringIO.new
    $stdout = out
    $stderr = err
    begin
      yield
    rescue SystemExit => e
      puts "error = #{e.inspect}"
    end
    "Output: #{out.string}\n Errors:#{err.string}"
  ensure
    $stdout = STDOUT
    $stdout = STDERR
  end

  RSpec.configure do |config|
    config.include RakeHelper
  end
end
