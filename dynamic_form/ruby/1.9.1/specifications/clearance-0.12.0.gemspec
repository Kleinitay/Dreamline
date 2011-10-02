# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{clearance}
  s.version = "0.12.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Dan Croak}, %q{Mike Burns}, %q{Jason Morrison}, %q{Joe Ferris}, %q{Eugene Bolshakov}, %q{Nick Quaranto}, %q{Josh Nichols}, %q{Mike Breen}, %q{Jon Yurek}, %q{Chad Pytel}]
  s.date = %q{2011-06-30}
  s.description = %q{Rails authentication & authorization with email & password.}
  s.email = %q{support@thoughtbot.com}
  s.extra_rdoc_files = [%q{LICENSE}, %q{README.md}]
  s.files = [%q{LICENSE}, %q{README.md}]
  s.homepage = %q{http://github.com/thoughtbot/clearance}
  s.rdoc_options = [%q{--charset=UTF-8}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Rails authentication & authorization with email & password.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, [">= 3.0"])
      s.add_runtime_dependency(%q<diesel>, ["~> 0.1.4"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
    else
      s.add_dependency(%q<rails>, [">= 3.0"])
      s.add_dependency(%q<diesel>, ["~> 0.1.4"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    end
  else
    s.add_dependency(%q<rails>, [">= 3.0"])
    s.add_dependency(%q<diesel>, ["~> 0.1.4"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
  end
end
