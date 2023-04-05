# frozen_string_literal: true

require_relative 'lib/outboxable/version'

Gem::Specification.new do |spec|
  spec.name = 'outboxable'
  spec.version = Outboxable::VERSION
  spec.authors = ['Brusk Awat']
  spec.email = ['broosk.edogawa@gmail.com']

  spec.summary = 'An opiniated Gem for Rails applications to implement the transactional outbox pattern.'
  spec.description = 'The Outboxable Gem is tailored for Rails applications to implement the transactional outbox pattern. It currently only supports ActiveRecord.'
  spec.homepage = 'https://github.com/broosk1993/outboxable'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.2'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/broosk1993/outboxable'
  spec.metadata['changelog_uri'] = 'https://github.com/broosk1993/outboxable/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bunny', '>= 2.19.0'
  spec.add_dependency 'connection_pool', '~> 2.3.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
