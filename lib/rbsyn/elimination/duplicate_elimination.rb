class DuplicateElimiation < EliminationStrategy
  def self.eliminate(progs)
    Set[*progs].to_a
  end
end
