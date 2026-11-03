An illustrative specification. The ticket and details are invented to show the level of detail.

````markdown
---
id: abc-123_error-rate-by-region
ticket: https://tracker.example.com/ABC-123
---

# Error rate by region

## Ticket
See [ABC-123](https://tracker.example.com/ABC-123). The ticket holds the intent;
this specification does not restate it.

## Premise
- Every processed order already records whether it ended in an error.
- Orders carry region context, so results can be grouped by region without new data.
- The report is read by people comparing one run against a frozen baseline.

## Approach
Add the error rate as a per-region breakdown alongside the existing summary. The breakdown is
computed from processed orders after processing, so the stored data and the interfaces do not
change. Regions with fewer than five orders are grouped as "other" so small samples do not
read as regressions.

### Acceptance checks
- A sample run reports a per-region error rate that sums to the overall rate.
- A region with fewer than five orders appears only under "other".

## Risks
- Grouping small regions hides a real regression in one of them. The reviewer decides
  whether five is the right threshold before build.

## Out of scope
- Alerting on the rate; this specification only reports it.
````
