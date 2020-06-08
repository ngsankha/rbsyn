class EliminationStrategy
  def self.eliminate(progs)
    raise RbSynError, "Not implemented"
  end
end

# Load all elimination strategies
Dir[File.join(File.dirname(__FILE__), "*.rb")].each { |f| require f }

ELIMINATION_ORDER = [
  DuplicateElimiation,
  # MinSizeElimination,
  TestElimination
]
