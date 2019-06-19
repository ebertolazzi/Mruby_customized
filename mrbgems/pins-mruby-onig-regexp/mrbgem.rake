MRuby::Gem::Specification.new('mruby-onig-regexp') do |spec|
  spec.license = 'MIT'
  spec.authors = 'mattn'
  spec.cc.defines       += ['HAVE_ONIGURUMA_H']
  spec.linker.libraries << ['onig']
end
