# -*- encoding: utf-8 -*-
# stub: json-schema 2.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "json-schema"
  s.version = "2.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.8") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Kenny Hoxworth"]
  s.date = "2016-02-26"
  s.email = "hoxworth@gmail.com"
  s.extra_rdoc_files = ["README.md", "LICENSE.md"]
  s.files = ["LICENSE.md", "README.md"]
  s.homepage = "http://github.com/ruby-json-schema/json-schema/tree/master"
  s.licenses = ["MIT"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")
  s.rubygems_version = "2.4.8"
  s.summary = "Ruby JSON Schema Validator"

  s.installed_by_version = "2.4.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<minitest>, ["~> 5.0"])
      s.add_development_dependency(%q<webmock>, [">= 0"])
      s.add_development_dependency(%q<bundler>, [">= 0"])
      s.add_runtime_dependency(%q<addressable>, ["~> 2.3.8"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<minitest>, ["~> 5.0"])
      s.add_dependency(%q<webmock>, [">= 0"])
      s.add_dependency(%q<bundler>, [">= 0"])
      s.add_dependency(%q<addressable>, ["~> 2.3.8"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<minitest>, ["~> 5.0"])
    s.add_dependency(%q<webmock>, [">= 0"])
    s.add_dependency(%q<bundler>, [">= 0"])
    s.add_dependency(%q<addressable>, ["~> 2.3.8"])
  end
end
