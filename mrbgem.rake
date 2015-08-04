MRuby::Gem::Specification.new('mjruby') do |spec|
  spec.license = 'MIT'
  spec.author  = 'MRuby Developer'
  spec.summary = 'mjruby'
  spec.bins    = ['mjruby']

  spec.add_dependency 'mruby-print', :core => 'mruby-print'
  spec.add_dependency 'mruby-mtest', :mgem => 'mruby-mtest'
  spec.add_dependency 'mruby-bin-mirb', :core => 'mruby-bin-mirb'
  spec.add_dependency 'mruby-process', :github => 'jkutner/mruby-process'
  spec.add_dependency 'mruby-env', :mgem => 'mruby-env'
  spec.add_dependency 'mruby-dir', :mgem => 'mruby-dir'
  spec.add_dependency 'mruby-string-ext', :core => 'mruby-string-ext'
  spec.add_dependency 'mruby-io', :github => 'hone/mruby-io'
  spec.add_dependency 'mruby-pure-regexp', :mgem => 'mruby-pure-regexp'

end
