# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{acts_as_state_machine}
  s.version = "2.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{RailsJedi}, %q{Scott Barron}]
  s.date = %q{2010-02-14}
  s.description = %q{This act gives an Active Record model the ability to act as a finite state machine (FSM).}
  s.email = %q{railsjedi@gmail.com}
  s.extra_rdoc_files = [%q{README}]
  s.files = [%q{README}]
  s.homepage = %q{http://github.com/jcnetdev/acts_as_state_machine}
  s.rdoc_options = [%q{--main}, %q{README}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{Allows ActiveRecord models to define states and transition actions between them}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activerecord>, [">= 2.1"])
    else
      s.add_dependency(%q<activerecord>, [">= 2.1"])
    end
  else
    s.add_dependency(%q<activerecord>, [">= 2.1"])
  end
end
