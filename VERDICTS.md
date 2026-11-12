# VBAF Verdicts -- tested on public data

Every new use of VBAF gets an honest verdict before it is offered to anyone. The rules are fixed before the data is seen: the decision, a public case with a known answer, the simple rule VBAF must beat, and what counts as YES. The test data is used exactly once. A NO is published just like a YES.

| # | Decision | Public case | Simple rule | Result | Verdict |
|---|---|---|---|---|---|
| B12 | Maintenance: service now or keep running? | NASA C-MAPSS FD001, 100 engines run to failure (70 for training, 30 for the test) | Fixed service interval (127 cycles) | 38.9 % lower cost per cycle, 0 failures (rule: 0) | **YES** (2026-11-09) |
| B01 | Electricity: when to run a 1-hour job within the next 48 hours, planned at 08:00 | Energinet day-ahead prices, price area DK2, 2015-2025 (test: 637 days in 2024-2025) | Cheapest hour already known at 08:00 | 4.3 % lower average price (required: 10 %) | **NO** (2026-11-09) |
| B11 | Heating: forecast the next day's district-heating use for one house | One house, daily meter readings 2020-2023 (data withdrawn by the owner 2026-11-12) and DMI daily mean temperature, a nearby DMI station (test: 218 days in 2022/23) | Degree-day model (base 17 C) | 38.1 % lower mean absolute error | **YES** (2026-11-09) |
| B13 | Hotel bookings: resell the room because this booking will probably be canceled? | Hotel Booking Demand, 2 hotels in Portugal, 119,390 bookings 2015-2017 (test: 40,687 arrivals in 2017) | Resell when the deposit is non-refundable, or when there is no deposit and the lead time is at least T days | 7.8 % higher net gain per booking (required: 10 %) | **NO** (2026-11-09) |
| B14 | Maintenance under hard conditions: service now or keep running? | NASA C-MAPSS FD004, 249 engines run to failure, 6 operating conditions and 2 fault modes (test: engines 212-249) | Fixed service interval (138 cycles) | 51.8 % lower cost per cycle, 0 failures (rule: 1) | **YES** (2026-11-09) |
| B15 | Maintenance with a safety margin: service now or keep running, with at least 10 cycles left? | NASA C-MAPSS FD002, 260 engines run to failure, 6 operating conditions (test: engines 222-260) | Fixed service interval (126 cycles), same margin | 53.4 % lower cost per cycle, 0 failures (rule: 2), every service with at least 11 cycles left | **YES** (2026-11-09) |
| B16 | Heating in many buildings: forecast the next day's heat use with one shared brain | Building Data Genome Project 2, 152 buildings with hot-water meters on 7 sites (test: 2017) | Degree-day model per building | 3.1 % lower relative error (required: 10 %) | **NO** (2026-11-09) |
| B17 | Maintenance with a safety margin, two fault modes: service now or keep running, with at least 10 cycles left? | NASA C-MAPSS FD003, 100 engines run to failure, 1 operating condition and 2 fault modes (test: engines 86-100) | Fixed service interval (151 cycles), same margin | 56.5 % lower cost per cycle, 2 failures (rule: 4) | **YES, with caveat** (2026-11-09) |
| B18 | Heating in many buildings, one brain per building: forecast the next day's steam use | Building Data Genome Project 2, 319 buildings with steam meters on 6 sites (test: 2017) | The better of the degree-day model and yesterday's use plus the change in degree days (no AI) | Median relative error 0.272 against 0.136 for the rule without AI | **NO** (2026-11-09) |
| B04 | CPU congestion on hypervisors: each morning, flag the hosts that will have CPU ready above 30 seconds that day | SAP Cloud Infrastructure Dataset, 123 hypervisors in one data centre (test: 6 days, August 2024) | Alarm if yesterday's maximum CPU ready was at least 25 seconds (no AI) | 10.9 % lower cost (required: 10 %) | **YES, with caveat** (2026-11-10) |
| B19 | Repeat of B04 in a second data centre, with rule and brain frozen in advance | SAP Cloud Infrastructure Dataset, 146 hypervisors in data centre b (test: 12 days, August 2024) | Alarm if yesterday's maximum CPU ready was at least 25 seconds (no AI) | 1.3 % higher cost than the rule (required: 10 % lower) | **NO** (2026-11-10) |
| B10 | Weekly stock target per product: set next week's stock level for 200 products | UCI Online Retail II, a UK online shop, 200 products (test: 21 weeks, July to November 2011) | 80th percentile of the last 13 weeks' sales (no AI) | 1.3 % lower normalised cost (required: 10 %) | **NO** (2026-11-10) |
| B20 | Truck maintenance on real data: how close is Component X to repair, judged from the readouts so far | SCANIA Component X, 23,550 real trucks for training (test: 5,045 trucks) | Always warn at the highest level (no AI) | 8.7 % lower cost (required: 10 %) | **NO** (2026-11-11) |
| B05 | Battery wear: when to replace a lithium-ion cell, judged from its capacity at each check-up | KIT battery aging dataset (Luh and Blank), 228 lab cells under 76 operating conditions (test: 36 cells) | Replace below 90 % of the start capacity (no AI) | 22 % lower cost, 0 failures (rule: 0) | **YES** (2026-11-11) |
| B22 | Battery wear under fast charging: when to replace a cell, judged from its capacity at each check-up | MIT, Stanford and Toyota Research Institute (Severson et al. 2019), 124 lab cells under 72 fast-charging policies (test batch not used) | Replace below 84.5 % of nominal capacity (no AI) | At most 1.3 % lower cost possible, even with perfect foresight (required: 10 %) | **NO** at lamp 2, no test (2026-11-11) |

**B12 caveat:** the engine VBAF serviced last had only 1 cycle left. The brain goes all the way to the edge, so a real installation needs a safety margin, set during a shadow period before it is trusted.

**B01 note:** the brain learned something, and a perfect forecast would have saved 43 %, but prices and calendar alone were not enough. Tomorrow's price is driven by wind and demand, so a new attempt needs public wind and demand forecasts as input, a new lock and fresh test data.

**B11 note:** a rule without AI (yesterday's use plus the change in degree days) was 22 % better than the degree-day model, and the VBAF brain was about 20 % better again. The case is one house with one meter, so it shows the method, not that it works for every building.

**B13 note:** the simple rule was first locked to resell only bookings without a deposit. Before any result was computed, it was corrected to also resell non-refundable bookings, which in this dataset are almost always canceled. That made the rule stronger, and it decided the case: VBAF found a real extra gain, but not enough. Gain per booking: resold and canceled = rate x nights; resold but the guest arrives = -2 x rate x nights.

**B14 note:** B14 repeats B12 on the hardest NASA subset, to test that the B12 result was not luck. The same caveat applies: the engine VBAF serviced last had only 1 cycle left, so a real installation needs a safety margin, set during a shadow period.

**B15 note:** B15 removes the caveat from B12 and B14. A service with fewer than 10 cycles left counted as a failure, for the rule and the brain alike. VBAF kept the margin on every test engine and still won by more than half.

**B16 note:** a rule without AI (yesterday's use plus the change in degree days) beat the VBAF brain in every period, so one shared brain did not add value across many different buildings. The error measure (the mean over buildings of each building's error relative to its own average) also turned out to be dominated by a few buildings; a new attempt needs a robust measure. B11 (one house) stands, but it does not extend to many buildings on this basis.

**B17 note:** the lock was met, but VBAF had 2 failures on 15 test engines, against 0 in B12, B14 and B15. With two fault modes, a 10-cycle margin was not enough, and 2 failures in 15 is not good enough for a customer as it stands. VBAF still clearly beat a fixed interval; the margin or threshold for a real installation must be set during a shadow period.

**B18 note:** B18 redid B16 with one brain per building, a median as a robust measure, and a stricter lock: VBAF had to beat the best simple rule, not just the degree-day model. The rule without AI was twice as good as the VBAF brains. For daily heat use in large buildings, a simple rule is the right tool; VBAF wins on wear that builds up over time, as in B12, B14 and B15.

**B04 note:** the lock was met by a hair. The whole difference was one missed congestion day (cost 41 against 46, with 31 congestion days in the test), and on the selection period the brain was 4.5 % worse than the rule. The direction held at other cost ratios (7.1 % better at 3, 17.9 % at 10), but the gain is small and unstable. It must be proven in the customer's own shadow period before it is used.

**B19 note:** B19 is the check on B04. The B04 brain was used unchanged in a data centre it had never seen, over twice as many test days (142 congestion days against 31). The rule without AI was slightly better (cost 234 against 237). B04's YES did not hold: for CPU congestion on hypervisors, a simple rule is the right tool. Data centre b had only 4 training days, so the brain was not retrained there. A customer's own shadow period could change this, but that is not proven.

**B10 note:** the brain was slightly better than the rule (5345 against 5418), but far from the 10 % needed. At a higher shortage cost (9 per unit) the brain was 7.5 % better; at a lower one (2) it was worse. The data is sales, not demand, so sold-out weeks hide lost sales. For weekly stock targets, a percentile rule is the right tool.

**B20 note:** the first maintenance test on real field data. On selection the brain was 21 % cheaper than the rule, but in the test only 8.7 %, below the locked 10 %. The brain halved the warnings to healthy trucks (2,697 of 4,903, where the rule warns all), but it missed 43 of 142 trucks close to repair, which the rule never misses. The maintenance YES verdicts (B12, B14, B15 and B17) are on NASA's simulated engines.

**B05 note:** lab data, not cells in the field. Brain and rule replaced the same 30 test cells and neither had a failure, but the brain let the cells run 454 check-ups against 354 for the rule, so the cells were used about 28 % longer before replacement. The rule's 90 % was at the edge of its locked grid, so a rule above 90 % was never tested; against the next best rule (89 %) the brain was 17 % cheaper. The test has only 36 cells.

**B22 note:** lab cells again, from a second lab. The rule replaces each cell at the first check-up below 84.5 % of nominal capacity, and on selection it lost only 10 of 792 possible check-ups against perfect foresight. Even a brain that knew the future could be at most 1.3 % cheaper on selection (2.1 % on training), so the locked 10 % was out of reach. The leg was closed at lamp 2 (is there room for a brain?) without building a brain or running the test. Where wear is even and uniform, a simple threshold is enough; B05 had room for a brain because its cells aged under 76 different conditions.

Cost model for B12: planned service = 1, failure = 10. Data: A. Saxena, K. Goebel, D. Simon and N. Eklund, Damage Propagation Modeling for Aircraft Engine Run-to-Failure Simulation, PHM08 (NASA).

Data for B01: Energi Data Service, Energinet (dataset Elspotprices, price area DK2, EUR/MWh).

Data for B11: the house owner's own meter readings, published with his consent (data withdrawn by the owner 2026-11-12; the meter labels the unit KwH), and DMI open data, a nearby DMI station.

Data for B13: Hotel Booking Demand, N. Antonio, A. de Almeida and L. Nunes, Data in Brief (2019), via TidyTuesday (2020-02-11).

Data for B14: the same NASA C-MAPSS data as B12, subset FD004.

Data for B15: the same NASA C-MAPSS data as B12, subset FD002.

Data for B16: The Building Data Genome Project 2 (C. Miller et al., Scientific Data, 2020), BUDS Lab on GitHub.

Data for B17: the same NASA C-MAPSS data as B12, subset FD003.

Data for B18: the same Building Data Genome Project 2 as B16, steam meters.

Data for B04: A. Uhlig, I. Braun and M. Waehlisch, The SAP Cloud Infrastructure Dataset (IMC '25), Zenodo 10.5281/zenodo.17357494, CC BY 4.0, data centre a. Cost model: alarm = 1, missed congestion day = 5.

Data for B19: the same SAP Cloud Infrastructure Dataset as B04, data centre b.

Data for B10: D. Chen, Online Retail II, UCI Machine Learning Repository (dataset 502), CC BY 4.0. Cost model: 1 per unit left over, 4 per unit short, divided by each product's average weekly sales in training.

Data for B20: T. Lindgren, O. Steinert, O. Andersson Reyna, Z. Kharazian and S. Magnusson, SCANIA Component X Dataset version 3, Scania CV AB, DOI 10.5878/bnh5-ka77, CC BY 4.0. Cost model: the official cost table, 7 to 10 for an early warning and 200 to 500 for a late one.

Data for B05: M. Luh and T. Blank, Comprehensive battery aging dataset: capacity and impedance fade measurements of a lithium-ion NMC/C-SiO cell, version 2, KIT, DOI 10.35097/1969, CC BY 4.0. Cost model: replacement = 1, failure = 10, per check-up run.

Data for B22: K. A. Severson et al., Data-driven prediction of battery cycle life before capacity degradation, Nature Energy 4, 383-391 (2019); data from data.matr.io/1 (Toyota Research Institute), CC BY 4.0. Processed: check-ups every 25 cycles, cells excluded and merged as in the notebook Load Data.ipynb by the authors. Cost model: replacement = 1, failure = 10, per check-up run.
