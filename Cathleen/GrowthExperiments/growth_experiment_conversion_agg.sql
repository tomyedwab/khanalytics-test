### join growth experiment participants to conversions
## Destination: cathleen.growth_experiment_conversion_agg
SELECT
  conversions.bingo_id as bingo_id,
  conversion,
  device,
  language,
  app,
  product,
  domain,
  registered,
  participants.rounds as rounds,
  participants.experiment as experiment,
  participants.alternative as alternative,
  et.num_participants as num_participants,
FROM  {{table_conversions}} conversions
INNER JOIN {{table_participants}} participants
    ON conversions.bingo_id = participants.bingo_id
INNER JOIN bigbingo.experiment_totals et
    ON et.experiment = participants.experiment
    AND et.alternative = participants.alternative
WHERE conversions.start_time >= participants.round_participation_time
