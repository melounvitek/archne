require "solargraph"

# Solargraph 0.60.3 maps files concurrently with requests that iterate the same hash.
module SolargraphMappingPatch
  def next_map
    mutex.synchronize { super }
  end
end

Solargraph::Library.prepend(SolargraphMappingPatch) if Solargraph::VERSION == "0.60.3"
