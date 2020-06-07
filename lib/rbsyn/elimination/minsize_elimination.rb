class MinSizeElimination < EliminationStrategy
  def self.eliminate(progs)
    least = progs.map { |prog| ProgSizePass.prog_size(prog.to_ast, nil) }.min
    progs.reject { |prog| ProgSizePass.prog_size(prog.to_ast, nil) > least }
  end
end
