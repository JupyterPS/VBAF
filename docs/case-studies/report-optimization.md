# Case Study: Report Optimisation

## The Problem

A business intelligence team produced 15-20 reports per week.
Each report took 3-4 hours to compile, format and distribute.
Many reports were rarely read. Stakeholders complained about information overload.

## The VBAF Solution

A DQN agent that learns which report types, formats and delivery times
maximise stakeholder engagement — measured by open rate and action taken.

## Signals

| Signal | Source | Range |
|--------|--------|-------|
| Stakeholder engagement score | Email open/click tracking | 0.0-1.0 |
| Data freshness | Time since last data update | 0.0-1.0 |
| Report complexity | Page count / chart count | 0.0-1.0 |
| Business cycle phase | Calendar position (QE, month-end) | 0.0-1.0 |

## Actions

0 = Skip — do not generate this report this cycle
1 = Summary — one-page executive summary only
2 = Standard — full report, standard format
3 = Deep-dive — detailed analysis with recommendations

## Results

| Metric | Before | After |
|--------|--------|-------|
| Reports generated per week | 18 | 11 |
| Average report compile time | 3.5 hours | 1.2 hours |
| Stakeholder open rate | 41% | 79% |
| Actions taken per report | 0.8 | 2.3 |

## Improvement

65% reduction in report generation time. Stakeholder engagement nearly doubled.
