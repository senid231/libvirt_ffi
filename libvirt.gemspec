# frozen_string_literal: true

require_relative 'lib/libvirt/version'

Gem::Specification.new do |spec|
  spec.name          = 'libvirt_ffi'
  spec.version       = Libvirt::VERSION
  spec.authors       = ['Denis Talakevich']
  spec.email         = ['senid231@gmail.com']

  spec.summary       = 'Libvirt FFI'
  spec.description   = 'Libvirt FFI'
  spec.homepage      = 'https://github.com/senid231/libvirt_ffi'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'ffi', '>= 1.0'

  spec.add_development_dependency 'rubocop', '~> 0.80.1'
end
