# Case Study: Email Triage

## The Problem

An IT support team received 200-400 emails per day.
Manual triage took 2-3 hours every morning.
Urgent tickets were sometimes buried under low-priority requests.
SLA breaches were happening weekly.

## The VBAF Solution

A DQN agent trained to classify and prioritise incoming emails.
Observes 4 signals extracted from each email and assigns a priority action.

## Signals

| Signal | Source | Range |
|--------|--------|-------|
| Sender seniority | Active Directory group | 0.0-1.0 |
| Keyword urgency score | Subject line analysis | 0.0-1.0 |
| Time since last contact | Exchange metadata | 0.0-1.0 |
| SLA proximity | Ticket age vs SLA threshold | 0.0-1.0 |

## Actions

0 = Queue — add to normal queue, handle in order
1 = Prioritise — move to top of queue
2 = Escalate — alert team lead immediately
3 = Auto-respond — send acknowledgement and create ticket

## Results

| Metric | Before | After |
|--------|--------|-------|
| Morning triage time | 2.5 hours | 33 minutes |
| SLA breaches per month | 8 | 1 |
| Misrouted tickets | 23% | 4% |
| Team satisfaction | Low | High |

## Improvement

+78% reduction in triage time. SLA compliance improved from 87% to 98%.
