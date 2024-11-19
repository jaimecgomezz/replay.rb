require_relative 'lib/replay/scenario/version'

Gem::Specification.new do |spec|
  spec.name = 'replay-scenario'
  spec.version = Replay::Scenario::VERSION
  spec.authors = ['jaimecgomezz']
  spec.email = ['work@jaimecgomezwork.com']

  spec.summary = 'Replay interactive scenarios'
  spec.description = 'Replay interactive scenarios'
  spec.homepage = 'https://github.com/jaimecgomezz/replay.rb'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/jaimecgomezz/replay.rb'
  spec.metadata['source_code_uri'] = 'https://github.com/jaimecgomezz/replay.rb'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency('httparty', '~> 0.22.0')
  spec.add_dependency('pry', '~> 0.14.2')
end
