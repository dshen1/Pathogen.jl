"""
utilities.jl - basic utilities for dealing with sequence data
Justin Angevaare
May 2015
"""
import Base.convert

function convert(::Type{Int64}, x::Nucleotide2bitSeq)
  """
  Add a conversion method to move from Nucleotide to an integer
  """
  return sub2ind((2,2), x.b1 .+1, x.b2 .+1)
end

function convert(::Type{Nucleotide2bitSeq}, x::Vector{Int64})
  """
  Add a conversion method to move from an integer to a nucleotide sequence
  """
  b1,b2 = ind2sub((2,2), x)
  if length(x) == 1
    return Nucleotide2bitSeq(convert(BitArray, [b1 - 1]), convert(BitArray, [b2 - 1]))
  else
    return Nucleotide2bitSeq(convert(BitArray, b1 - 1), convert(BitArray, b2 - 1))
  end
end

function generate_seq(n::Int, π_A::Float64, π_T::Float64, π_C::Float64, π_G::Float64)
  """
  Generate a nucleotide sequence of length `n`, with specific nucleotide frequencies
  """
  @assert(sum([π_A, π_T, π_C, π_G]) == 1, "Nucleotide frequencies must sum to 1")
  @assert(all(0 .< [π_A, π_T, π_C, π_G] .< 1), "Each nucleotide frequency must be between 0 and 1")
  sequence = fill(0, n)
  for i = 1:n
    sequence[i]=findfirst(rand(Multinomial(1, [π_A, π_T, π_C, π_G])))
  end
  return nucleotide("AGCU"[sequence])
end

function generate_2bitseq(n::Int, π_A::Float64, π_T::Float64, π_C::Float64, π_G::Float64)
  """
  Generate a nucleotide sequence of length `n`, with specific nucleotide frequencies
  """
  @assert(sum([π_A, π_T, π_C, π_G]) == 1, "Nucleotide frequencies must sum to 1")
  @assert(all(0 .< [π_A, π_T, π_C, π_G] .< 1), "Each nucleotide frequency must be between 0 and 1")
  return convert(Nucleotide2bitSeq, findn(rand(Multinomial(1, [π_A, π_T, π_C, π_G]),n))[1])
end

function findstate(population::Population, individual::Int64, time::Float64)
  """
  Find the disease state of a specific individual
  """
  if sum(population.events[individual][1] .< time) == 0
    return "S"
  elseif sum(population.events[individual][1] .< time) > sum(population.events[individual][3] .< time)
    return "E"
  elseif sum(population.events[individual][3] .< time) > sum(population.events[individual][4] .< time)
    return "I"
  elseif sum(population.events[individual][1] .< time) == sum(population.events[individual][4] .< time)
    return "S*"
  else
    return "unknown"
  end
end

function plotdata(population, time)
  """
  Create dataframes with all necessary plotting information
  """
#   states = DataFrame(x = Float64[], y = Float64[], state = ASCIIString[])
  states = DataFrame(id = fill(NaN,4), x = fill(NaN,4), y = fill(NaN,4), state = ["S", "E", "I", "S*"])
  routes = DataFrame(x = Float64[], y = Float64[], age = Float64[])
  for i = 2:length(population.events)
    states = vcat(states, DataFrame(x = population.history[i][1][1,find(time .> population.events[i][5])[end]], y = population.history[i][1][2,find(time .> population.events[i][5])[end]], state = findstate(population, i, time)))
    for j = 1:sum(population.events[i][1].< time)
      source = population.events[i][2][j]
      age = time - population.events[i][1][j]
      if source > 1
        routes = vcat(routes, DataFrame(x = population.history[i][1][1,find(time .> population.events[i][5])[end]], y = population.history[i][1][2,find(time .> population.events[i][5])[end]], age = "$age"))
        routes = vcat(routes, DataFrame(x = population.history[source][1][1,find(time .> population.events[source][5])[end]], y = population.history[source][1][2,find(time .> population.events[source][5])[end]], age = "$age"))
      end
    end
  end
  return states, routes
end

function geneticdistance(ancestor::Vector{Nucleotide}, descendent::Vector{Nucleotide}, substitution_matrix::Array)
  """
  Compute the genetic distance between two nucleotide sequences based on a `substitution_matrix`
  """
  @assert(length(ancestor) == length(descendent), "Sequences must be equal in length")
  nucleotide_ref = nucleotide("AGCU")
  rate_vector = Float64[]
  for i = 1:length(ancestor)
    if ancestor[i] != descendent[i]
     push!(rate_vector, substitution_matrix[ancestor[i] .== nucleotide_ref, descendent[i] .== nucleotide_ref])
    end
  end
  rate_vector .^= -1
  return sum(rate_vector)
end
