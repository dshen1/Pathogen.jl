function loglikelihood(riskparams::RiskParameters,
                       events::Events,
                       riskfuncs::RiskFunctions,
                       population::DataFrame)
  # Initialize
  ll = 0.
  eventtimes = [events.exposed events.infected events.removed]
  rates = initialize_rates(population, riskfuncs, riskparams)
  networkrates = [fill(0., events.individuals), fill(0., (events.individuals, events.individuals))]

  # Find event order
  eventorder = sortperm(eventtimes[:])

  for i = 1:length(eventorder)
    # Stop log likelihood calculation after the last event
    isnan(eventtimes[eventorder[i]]) && break

    # Stop log likelihood calculation anytime the loglikelihood goes to -Inf
    if isnan(ll)
      ll = -Inf
    end
    ll == -Inf && break

    # Convert linear index to an event tuple (individual, event type)
    individual, eventtype = ind2sub(size(eventtimes), eventorder[i])

    # Find the rate total
    ratetotal = sum([sum(rates[1]);
                     sum(rates[2]);
                     sum(rates[3]);
                     sum(rates[4])])

    if i > 1
      # Find the time difference between consecutive events
      ΔT = eventtimes[eventorder[i]] - eventtimes[eventorder[i-1]]

      # loglikelihood contribution of event time
      ll += loglikelihood(Exponential(1/ratetotal), [ΔT])
    end

    # loglikelihood contribution of specific event
    if eventtype == 1
      networkrates[1][individual] = rates[1][individual]
      networkrates[2][:, individual] = rates[2][:, individual]
      exposuretotal = networkrates[1][individual] + sum(networkrates[2][:, individual])
      ll += log(exposuretotal/ratetotal)
      update_rates!(rates, (1, individual))
    else
      ll += log(rates[eventtype+1][individual]/ratetotal)
      update_rates!(rates, (eventtype+1, individual))
    end
  end
  return ll, networkrates
end
