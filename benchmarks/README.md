# Benchmarks

Ad hoc `benchmark-ips` scripts for comparing two candidate implementations of
a specific method - not whole-request profiling (use rack-mini-profiler or
`rake profiling:stackprof` for that; see
[docs/performance-profiling.md](../docs/performance-profiling.md)).

One file per question, e.g. `deposit_wizard_presenter_bench.rb`. Not
autoloaded, not run by rspec or CI - run manually:

```
bundle exec ruby benchmarks/deposit_wizard_presenter_bench.rb
```

Example:

```ruby
require_relative '../config/environment'
require 'benchmark/ips'

Benchmark.ips do |x|
  x.report('map + flatten') { [[1, 2], [3, 4]].map { |a| a }.flatten }
  x.report('flat_map') { [[1, 2], [3, 4]].flat_map { |a| a } }
  x.compare!
end
```
