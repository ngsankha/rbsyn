lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rbsyn/version"

Gem::Specification.new do |spec|
  spec.name          = "rbsyn"
  spec.version       = Rbsyn::VERSION
  spec.authors       = ["Sankha Narayan Guria"]
  spec.email         = ["sankha93@gmail.com"]

  spec.summary       = %q{Synthesize ruby programs}

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-hooks"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "minitest-reporters"

  spec.add_dependency "parser"
  spec.add_dependency "unparser"
  spec.add_dependency "rdl"
end
