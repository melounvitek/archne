require "solargraph"

# Solargraph 0.60.3 and 0.60.4 map files concurrently with requests that iterate the same hash.
module SolargraphMappingPatch
  def next_map
    mutex.synchronize { super }
  end
end

affected_versions = %w[0.60.3 0.60.4]
Solargraph::Library.prepend(SolargraphMappingPatch) if affected_versions.include?(Solargraph::VERSION)
