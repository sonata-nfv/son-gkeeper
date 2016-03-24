# -*- encoding: utf-8 -*-
# stub: rack-parser 0.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-parser"
  s.version = "0.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Arthur Chiu"]
  s.date = "2014-10-10"
  s.description = "Rack Middleware for parsing post body data for json, xml and various content types"
  s.email = ["mr.arthur.chiu@gmail.com"]
  s.homepage = "https://www.github.com/achiu/rack-parser"
  s.rubyforge_project = "rack-parser"
  s.rubygems_version = "2.4.8"
  s.summary = "Rack Middleware for parsing post body data"

  s.installed_by_version = "2.4.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
  end
end
