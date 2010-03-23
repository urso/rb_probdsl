
spec = Gem::Specification.new do |s|
  s.name        = 'rb_probdsl'
  s.version     = '0.0.1'
  s.licenses    = 'BDS3'
  s.summary     = 'do probabilistic programming in ruby'
  s.files       = Dir['lib/**/*.rb'] + Dir['examples/**/*.rb'] + ['LICENSE']
  s.has_rdoc    = true
  s.author      = 'Steffen Siering'
  s.email       = 'steffen <dot> siering -> gmail <dot> com'
  s.homepage    = 'http://github.com/urso/rb_probdsl'
  s.add_dependency('rb_prob')
  s.add_dependency('rb_delimcc')
end

