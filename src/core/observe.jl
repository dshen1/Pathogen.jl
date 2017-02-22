"""
Event observations
"""
type EventObservations
  infected::Vector{Float64}
  removed::Vector{Float64}
  individuals::Int64

  function EventObservations(infected::Vector{Float64}, removed::Vector{Float64})
    if length(infected) != length(removed)
      error("Infection and removal event time vectors must be of equal length")
    end
    return new(infected, removed, length(infected))
  end
end