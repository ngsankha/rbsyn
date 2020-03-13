require_relative "ast_node_count"

class Instrumentation
  @@prog = nil

  def self.reset!
    @@prog = nil
  end

  def self.load_config
    if ENV['']
  end

  def self.prog=(prog)
    @@prog = prog
  end
end
