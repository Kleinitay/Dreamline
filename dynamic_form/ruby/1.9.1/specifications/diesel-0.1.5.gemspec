# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{diesel}
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{thoughtbot, inc.}, %q{Joe Ferris}]
  s.date = %q{2011-07-02}
  s.description = %q{Develop your Rails engines like you develop your Rails applications.}
  s.email = %q{support@thoughtbot.com}
  s.executables = [%q{diesel}]
  s.files = [%q{bin/diesel}]
  s.homepage = %q{http://github.com/thoughtbot/diesel}
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Diesel makes your engine go.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<railties>, [">= 0"])
      s.add_development_dependency(%q<cucumber-rails>, ["~> 0.5.1"])
      s.add_development_dependency(%q<appraisal>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, ["~> 2.6.1"])
      s.add_development_dependency(%q<thin>, [">= 0"])
      s.add_development_dependency(%q<sqlite3-ruby>, [">= 0"])
    else
      s.add_dependency(%q<railties>, [">= 0"])
      s.add_dependency(%q<cucumber-rails>, ["~> 0.5.1"])
      s.add_dependency(%q<appraisal>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, ["~> 2.6.1"])
      s.add_dependency(%q<thin>, [">= 0"])
      s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
    end
  else
    s.add_dependency(%q<railties>, [">= 0"])
    s.add_dependency(%q<cucumber-rails>, ["~> 0.5.1"])
    s.add_dependency(%q<appraisal>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, ["~> 2.6.1"])
    s.add_dependency(%q<thin>, [">= 0"])
    s.add_dependency(%q<sqlite3-ruby>, [">= 0"])
  end
end
