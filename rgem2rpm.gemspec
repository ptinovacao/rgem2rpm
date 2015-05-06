# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/lib/rgem2rpm/version'

Gem::Specification.new do |s|
   s.name                      = %q{rgem2rpm}
   s.version                   = RGem2Rpm::VERSION
   s.required_ruby_version     = Gem::Requirement.new(">= 1.8.6")
   s.required_rubygems_version = Gem::Requirement.new(">= 1.4.2") if s.respond_to?(:required_rubygems_version=)
   s.date                      = Time.now.strftime("%Y-%m-%d")
   s.authors                   = ["Sergio Freire", "Nuno Correia", "Joao Peixoto"]
   s.email                     = %q{sergio-s-freire@ptinovacao.pt}
   s.summary                   = %q{Convert ruby gems into rpm}
   s.license                   = "MIT"
   s.homepage                  = %q{https://github.com/ptinovacao/rgem2rpm}
   s.description               = %q{Application that enables conversion of rubygems to rpms.}
   s.bindir                    = 'bin'
   s.require_path              = "lib"
   s.executables               = 'rgem2rpm'
   s.files                     = Dir.glob("{lib}/**/*") + Dir.glob("{bin}/*") + Dir.glob("{conf}/*") + [__FILE__, 'Rakefile'] 
end
