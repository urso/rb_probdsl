
spec = Gem::Specification.new do |s|
  s.name        = 'rb_probdsl'
  s.version     = '0.0.4'
  s.licenses    = 'BDS3'
  s.summary     = 'do probabilistic programming in ruby'
  s.files       = Dir['lib/**/*.rb'] + Dir['examples/**/*.rb'] + ['LICENSE']
  s.has_rdoc    = true
  s.author      = 'Steffen Siering'
  s.email       = 'steffen <dot> siering -> gmail <dot> com'
  s.homepage    = 'http://github.com/urso/rb_probdsl'
  s.add_dependency('rb_prob', '>= 0.0.3')
  s.add_dependency('rb_delimcc', '>= 0.0.3')
end

