class EliminationStrategy
  def self.eliminate(progs)
    raise RuntimeError, "Not implemented"
  end
end

class BranchCountElimination < EliminationStrategy
  # only keeps programs with minimal number of branches
  def self.eliminate(progs)
    counts = progs.map { |prog| count_branches(prog) }
    min_count = counts.min
    selected_idx = counts.each_index.select{ |i| counts[i] == min_count }
    selected_progs = selected_idx.map { |idx| progs[idx] }
    return selected_progs
  end

  private
  def self.count_branches(prog)
    count = 1
    if prog.prog.is_a? Array
      RDL.type_cast(prog.prog, 'Array<ProgTuple>', force: true)
        .each { |subprog|
          count += count_branches(subprog)
      }
    end
    return count
  end
end

class DuplicateElimiation < EliminationStrategy
  def self.eliminate(progs)
    Set[*progs].to_a
  end
end

# class OrCountElimination < EliminationStrategy
#   # eliminate same programs, only keeps programs with longer branch conditions
#   def self.eliminate(progs)
#     or_map = {}
#     progs.map { |prog|
#       score = prog.branch.conds.size
#       unless or_map.key? prog.prog
#         or_map[prog.prog] = prog
#       else
#         old = or_score(or_map[prog.prog].branch.expr)
#         or_map[prog.prog] = prog if score > old
#       end
#     }
#     or_map.values
#   end
# end
