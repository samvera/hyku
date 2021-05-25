# Undefine Settings constant to allow for per-thread settings using Settings singleton
Object.send(:remove_const, Config.const_name) if Object.const_defined?(Config.const_name)
Settings.switch!
