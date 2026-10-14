# VBAF Vocabulary

Every AI term used in the VBAF kernel and its sister projects, each with a short explanation. Compiled from the kernel code (v6.2.0), the Evolution-Lab work, and a scan of function names and terms in VBAF-Center and VBAF-Platform on 13 Oct 2026.

**The Where column:** K = VBAF kernel · L = VBAF-Evolution-Lab · C = VBAF-Center · P = VBAF-Platform · BF = Brain Factory (planned).

**KF-n** refers to a numbered *kernel finding* (Danish: *kernefund*): a kernel bug found in the Lab and documented in the CHANGELOG.

**Two words with a strict meaning:** in this vocabulary a *brain* is a trained network that has passed a final test and has a datasheet. An *agent* is a task in a domain that a brain or a rule can drive. Words with two meanings are collected at the end.

## Contents

1. [Neural networks](#1-neural-networks)
2. [Deep networks](#2-deep-networks)
3. [Training and optimization](#3-training-and-optimization)
4. [Supervised learning, models and metrics](#4-supervised-learning-models-and-metrics)
5. [Reinforcement learning: the basics](#5-reinforcement-learning-the-basics)
6. [The algorithms](#6-the-algorithms)
7. [The DQN machinery](#7-the-dqn-machinery)
8. [Settings and search](#8-settings-and-search)
9. [Evolution and PBT (Evolution-Lab)](#9-evolution-and-pbt-evolution-lab)
10. [Measurement and proof](#10-measurement-and-proof)
11. [Failure modes and kernel findings](#11-failure-modes-and-kernel-findings)
12. [Worlds and pillars](#12-worlds-and-pillars)
13. [VBAF-Center](#13-vbaf-center)
14. [VBAF-Platform](#14-vbaf-platform)
15. [MLOps, explainability and time series](#15-mlops-explainability-and-time-series)
16. [Architecture, Brain Factory and Agent Factory](#16-architecture-brain-factory-and-agent-factory)
17. [Words with two meanings](#17-words-with-two-meanings)

## 1. Neural networks

| Term | Meaning | Where |
| --- | --- | --- |
| Neural network | A function made of layers of neurons that learns patterns by adjusting its weights. The core engine of VBAF. | K, P |
| Neuron | The smallest unit: adds up weighted inputs, adds a bias and passes the result through an activation function. | K |
| Weight | A number saying how much an input matters to a neuron. The weights are what gets learned. | K, P |
| Bias | An extra number in each neuron that shifts its starting point. Learned just like the weights. | K |
| Layer | A row of neurons working side by side. | K |
| Input layer | The network's entrance: one value per thing the network can see (the state). | K |
| Hidden layer | A layer between input and output where the network builds its own ways of seeing the data. | K |
| Output layer | The network's exit, e.g. one Q-value per action. | K |
| Architecture | The shape of the network, written as neurons per layer, e.g. 4-16-16-3. | K, L |
| Activation function | The function that shapes a neuron's output so the network can learn non-linear relationships. | K |
| Sigmoid | Activation that squeezes values into the range 0 to 1. The default in VBAF's hidden layers. | K |
| ReLU | Activation that lets positive values pass and sets negative values to 0. | K |
| Tanh | Activation that squeezes values into the range -1 to 1. | K |
| Linear | No shaping: output = input. Used in DQN's output layer so Q-values can grow large (KF-1). | K |
| Weighted sum | The bias plus the sum of inputs times weights. What a neuron computes before the activation. | K |
| Forward pass | Sending an input through all layers to get an output. | K |
| Predict | The kernel's forward-pass function. Returns a copy of the result (KF-4). | K |
| Backpropagation | The training method: the error is sent backwards through the layers, and each weight is adjusted by its share of the error. | K |
| Gradient | The direction and size of the change that reduces the error the most. | K |
| Delta | A neuron's share of the error during backpropagation. | K |
| Loss | A number for how far the network's answer is from the right one. Training tries to make it smaller. | K |
| MSE | Mean squared error: the loss VBAF uses. | K |
| Learning rate | How big a step the weights take at a time. Too low: nothing is learned (KF-14). Too high: unstable. | K, L, P |
| Epoch | One pass through the whole training set. | K, P |
| TrainSample | The kernel function that trains on one example: forward pass, loss and backpropagation. | K |
| Saturation | When an activation sits far out at one end, so the gradient is almost 0 and the network stops learning. | K, L |
| ExportState / ImportState | Save and load a network's weights. Since 6.1 these make real copies (KF-13). | K |
| Network engine | What computes the network: pure PowerShell (default) or the battery. Chosen with Set-VBAFNetEngine. | K |
| The battery | An optional C# engine that computes exactly the same as PowerShell, only about 8 times faster. | K, L |
| FastNeuralNetwork | The class behind the battery. | K, L |
| VBAFNetworkFactory | The one place where every network in VBAF is created, so the engine choice reaches everywhere. | K |
| Bit-identical | Gives exactly the same numbers down to the last bit. The requirement for the battery. | K, L |

## 2. Deep networks

| Term | Meaning | Where |
| --- | --- | --- |
| Deep learning | Networks with many layers that find for themselves the features in the data that matter. | K |
| CNN (convolutional neural network) | A network for images and grids: small filters slide over the data and find local patterns. | K |
| Convolution | Sliding a small filter over the data and computing a weighted sum at each position. | K |
| Filter (kernel) | The small grid of weights that slides over the data in a CNN. Not the same as the VBAF kernel. | K |
| Pooling | Shrinking an image by keeping, e.g., the largest number in each small patch. | K |
| Stride | How far the filter moves at each step. | K |
| Padding | Extra zeros around the data so the filter can also see the edges. | K |
| RNN | A network for sequences (text, time series) that remembers something from the previous step. | K |
| Hidden state | What an RNN carries from step to step. | K |
| LSTM | A type of RNN with "gates" that can remember further back. | K |
| GRU | A simpler version of the LSTM. | K |
| Autoencoder | A network that learns to compress data and unpack it again. Used for compression and for finding anomalies. | K |
| Encoder | The part that compresses the data. | K |
| Decoder | The part that unpacks it again. | K |
| Latent space | The compressed form the data takes in the middle of an autoencoder. | K |
| Embedding | A thing (e.g. a word) turned into a row of numbers where similar things lie close together. | K |
| Attention | A mechanism where the network itself weighs which parts of the input matter most. | K |
| Transfer learning | Reusing a network trained on one task for a new one. | K |
| Fine-tuning | Training a reused network a little further on the new task. | K |

## 3. Training and optimization

| Term | Meaning | Where |
| --- | --- | --- |
| Training | Letting a network adjust its weights from examples or experience. | K, L, P |
| Training sample | One input with the right answer, which the network learns from. | K, P |
| Optimizer | The rule for how the weights change based on the gradient. | K |
| Momentum | An optimizer technique that remembers the direction of previous steps, so training moves forward faster. | K |
| Adam | A widely used optimizer that adapts the step size for each weight. | K |
| Regularization | Techniques that keep the network from memorizing the training data. | K |
| L1 / L2 | Two forms of regularization that penalize large weights. | K |
| Dropout | Regularization where random neurons are switched off during training. | K |
| Batch normalization | Rescaling a layer's values along the way so training becomes more stable. | K |
| Softmax | Turns a row of numbers into probabilities that sum to 1. | K |
| Cross-entropy | A loss for classification with probabilities. | K |
| One-hot | A category written as a row of zeros with a single 1. | K |
| Early stopping | Stopping training when validation stops improving. | K |
| Learning curve | A curve of how score or loss develops during training. | K, L |
| Vanishing gradient | When the gradient becomes so small in the first layers that they hardly learn. | K |
| Exploding gradient | When the gradient becomes so large that training runs out of control. | K |
| Gradient clipping | Scaling large gradients down before they are used. | K |
| Xavier / He initialization | Methods for choosing good starting weights so training gets off to a good start. | K |
| Initialization | The choice of the network's starting weights. | K |
| Standardization | Scaling data to mean 0 and standard deviation 1. | K |
| Normalization | Scaling data to a fixed range, typically 0-1. | K, C |
| AutoML | Letting the machine try out models and settings by itself. | K |

## 4. Supervised learning, models and metrics

| Term | Meaning | Where |
| --- | --- | --- |
| Supervised learning | Learning from examples that come with the right answer. | K |
| XOR | The classic test problem: two inputs, the answer is 1 when exactly one of them is 1. Needs a hidden layer. | K |
| Dataset | A collection of examples. | K |
| Feature | One property of an example, e.g. CPU load. | K, P |
| Label | The right answer for an example. | K |
| Split (train/test) | Dividing data into a part to train on and a part to test on. | K |
| k-fold | Dividing data into k parts and testing on each part in turn. | K |
| Cross-validation | Several splits in a row, so the result does not depend on one random division. | K |
| Grid search | Trying every combination of some chosen settings. | K |
| Overfitting | When a model has memorized the training data instead of learning the pattern. | K |
| Classification | Putting something into a category. | K, C, P |
| Regression | Predicting a number. | K |
| Linear regression | A model that predicts a number with a straight line. | K |
| Logistic regression | A model that predicts the probability of a category. | K |
| Decision tree | A model that makes decisions with a series of yes/no questions. | K |
| Random forest | Many decision trees that vote. | K |
| Naive Bayes | A simple probability model for classification. | K |
| Clustering | Finding groups in data without labels. | K |
| k-means | Clustering that divides data into k groups, each around its own centre. | K |
| DBSCAN | Clustering that finds dense regions and can mark noise. | K |
| PCA | Compressing many features into fewer ones that capture most of the variation. | K |
| Imputation | Filling in missing values. | K |
| Encoder (data) | Turning categories into numbers. | K |
| Outlier | A value that lies far from the others. | K |
| Accuracy | The share of correct answers. | K |
| Confusion matrix | A table of right and wrong answers for each category. | K |
| Precision | Of the cases the model called positive, how many were. | K |
| Recall | Of the positive cases, how many the model found. | K |
| F1 | A single number combining precision and recall. | K |
| ROC / AUC | A curve and a number for how well a model separates two classes. | K |
| R² | How large a share of the variation a regression model explains. | K |
| RMSE / MAE | Two measures of the typical error of a regression model. | K |
| Model selection | Choosing the best model based on validation. | K |

## 5. Reinforcement learning: the basics

| Term | Meaning | Where |
| --- | --- | --- |
| Reinforcement learning (RL) | Learning from reward: the agent tries things out and learns what pays off. | K, L, P |
| Agent | The one that acts and learns in an environment. | K, L, C, P |
| Environment | The world the agent acts in. Returns a state and a reward after each action. | K, L |
| State | What the agent can see right now, as a row of numbers. | K, L |
| Action | A choice the agent can make. | K, L, C, P |
| Reward | A number saying how good an action was. | K, L |
| Episode | A run from start to finish, e.g. one shift. | K, L |
| Step | One action and its consequences. | K, L |
| Reset / Step | The environment's two functions: start a new episode, and carry out an action. | K |
| Done | The signal that an episode is over. | K |
| State space | All the states that can occur. | K |
| Action space | All the actions the agent can choose between. | K |
| Discrete actions | A few separate choices (e.g. 3 buttons). DQN's home ground and the case in all of VBAF's worlds. | K, L |
| Continuous actions | Choices on a scale, e.g. "turn it up 37 %". Need, e.g., PPO. | K |
| Policy | The agent's rule for which action it picks in each state. | K, L, P |
| Value / value function | How much reward the agent can expect from a state. | K |
| Q-value | How much total reward the agent can expect if it picks a particular action now. | K, L |
| Q-table | A table with one Q-value per state and action. Only works in small worlds. | K |
| Bellman equation | Q-value = reward now + gamma × best Q-value afterwards. The foundation of Q-learning. | K |
| Discount factor (gamma) | How much future reward counts compared with reward now (0-1). | K, L |
| Temporal difference (TD) | Learning from the difference between what was expected and what actually happened one step later. | K |
| Exploration / exploitation | Trying something new versus choosing what you know works (explore/exploit). | K, L |
| Epsilon | The probability of choosing a random action. | K, L |
| Epsilon-greedy | With probability epsilon a random action is chosen, otherwise the best one. | K |
| Epsilon decay | How fast epsilon falls. In VBAF it is multiplied in at every Replay call. | K, L |
| EpsilonMin | The lowest value epsilon falls to. | K |
| Greedy | Always choosing the action that looks best. Used when measuring. | K, L |
| Reward shaping | Adding extra rewards that guide the agent the right way. | K |
| Imitation learning | Learning by imitating an expert. | K, L |
| Teacher / demonstration | The expert (e.g. the EDF rule) and the examples the brain learns from. | L |
| Rollout / trajectory | A sequence of states, actions and rewards used for training. | K |
| Monte Carlo | Estimating something from many random playthroughs. | K |

## 6. The algorithms

| Term | Meaning | Where |
| --- | --- | --- |
| Q-learning | Classic RL: learns a Q-value for each state and action, typically in a table. | K |
| DQN (Deep Q-Network) | Q-learning with a neural network instead of a table, so large state spaces can be handled. The best-measured algorithm in VBAF. | K, L, P |
| Policy gradient | A family of methods that learn the policy directly (probabilities for actions) instead of Q-values. | K |
| Actor-critic | An actor chooses and a critic evaluates. Combines both approaches. | K |
| Actor | The part that chooses actions. | K |
| Critic | The part that judges how good a state or action is. | K |
| Advantage | How much better an action was than expected. | K |
| PPO (Proximal Policy Optimization) | An actor-critic method with a brake, so the policy does not change too much at a time. Present in the kernel but not yet honestly measured. | K, P |
| Clipping (PPO) | PPO's brake: changes to the policy are clipped at a limit. | K |
| GAE | A method for computing the advantage more stably. | K |
| Lambda | A GAE setting that trades off short-term and long-term estimates. | K |
| Entropy | How random a policy is. Used to keep exploration going. | K |
| A3C | Actor-critic with several workers that train at the same time and share one network. Present in the kernel, not honestly measured. | K |
| Worker | One of A3C's parallel agents. | K |

## 7. The DQN machinery

| Term | Meaning | Where |
| --- | --- | --- |
| DQNConfig | The settings for a DQN agent: learning rate, gamma, epsilon, batch and more. | K, L |
| DQNAgent | The kernel's DQN agent. | K, L |
| Main network | The network that is trained and chooses actions. | K |
| Target network | A copy of the main network that stays still for a while, so training has a fixed goal. | K, L |
| Frozen target | The target network really staying still. Not the case before 6.1 (KF-13). | K, L |
| SyncTargetNetwork | Copying the main network into the target network. | K |
| Target update (TargetUpdateFreq) | How many episodes pass between copies. | K, L |
| Experience replay | Storing experiences and later training on random samples of them. | K, L |
| Replay memory (MemorySize) | The store of experiences and its size. | K |
| Remember | Putting an experience into memory. | K |
| Replay | Training on a random sample (a batch) from memory. | K |
| Batch / BatchSize | The sample of experiences trained on at once, and how many it holds. | K, L |
| ReplayEvery | How many steps pass between Replay calls. | L |
| TrainingSteps | The number of training examples the agent has learned from. | K |
| LossHistory | The list of losses from each Replay. | K |

## 8. Settings and search

| Term | Meaning | Where |
| --- | --- | --- |
| Hyperparameter / setting | A setting that controls training but is not itself learned: learning rate, gamma, epsilon decay, target update. | K, L |
| Settings search | Trying many settings and keeping the one that does best on validation. | K, L |
| Random search | Settings search with randomly drawn settings. The method that worked in the Lab. | K, L |
| Invoke-VBAFSettingsSearch | The kernel's settings search (6.2) for any environment. | K |
| Measure-VBAFAgentScore | Measures an agent's average reward on given seeds. | K |
| Candidate | One brain with one set of settings in a search. | K, L |
| Checkpoint | A saved copy of a brain during training. | K, L |
| Best checkpoint | The saved copy that did best on validation. The one that is delivered. | K, L |
| Search ranges | The limits on which settings may be tried. | K, L |
| Log-uniform distribution | Drawing, e.g., learning rates so that 0.001-0.01 and 0.01-0.1 get equally many tries. | K, L |
| -Settings | The pillars' parameter for giving them their own settings (6.2). | K |
| Searched defaults | The settings the 4 enterprise pillars found for themselves (6.2, KF-14). | K |

## 9. Evolution and PBT (Evolution-Lab)

| Term | Meaning | Where |
| --- | --- | --- |
| Evolution | Letting many variants compete, keeping the best and changing them slightly. | L |
| Gene / genome | One setting, and the whole set of settings that describes a brain. | L |
| Generation | One round of evolution. | L |
| Population | The group of brains that compete. | L |
| Fitness | The number a brain is judged on in evolution. | L |
| Mutation | A small random change to a gene. | L |
| Selection | Which brains get to continue. | L |
| Parent / child | A brain and the changed copy made from it. | L |
| Lineage | The record of who descends from whom. | L |
| Champion | The best brain of an evolution run. | K, L |
| Control | The comparison brain with the original settings. | K, L |
| Genetic algorithm | Evolution where every new brain is trained from scratch. Tested in 4c and phase 6. | L |
| PBT (Population-Based Training) | Evolution in the middle of training: the worst brains take over the weights and genes of the best. Tested in phases 8a and 8b. | L |
| Inheritance | One brain taking over another's weights. | L |
| Exploit | The PBT step where a poor brain is replaced by a copy of a good one. | L |
| Perturbation | The PBT step where the copy's genes are changed slightly (×0.8 or ×1.25). | L |
| Equal compute | Giving every compared brain the same amount of training, so none wins just by training more. | L |
| Compute budget | The total amount of training a method may use. | L |

## 10. Measurement and proof

| Term | Meaning | Where |
| --- | --- | --- |
| Seed | The starting value of the random number generator. The same seed gives the same run. | K, L, P |
| Set-VBAFSeed | The kernel function that seeds every random number generator at once (KF-3). | K |
| Determinism / reproducibility | The same input and seed always giving the same result. | K, L |
| Training, validation and test seeds | Three separate sets: for training, for choosing the best, and for the final test. | K, L |
| Validation | Measuring brains on validation seeds to choose the best. | K, L, P |
| Final test | The last measurement, on fresh test seeds that were not used for choosing. | K, L, BF |
| The bar | What a brain must beat to count: typically the best fixed action or today's rule. | K, L |
| Best fixed action | The action that scores most if you always choose it. VBAF's honest bar. | K, L |
| Random policy | Choosing at random. The old bar, too easy. | K |
| Oracle | A policy that knows the answer. Shows how much there is to gain. | L |
| Baseline | A point of comparison: a rule, an average or a normal state. | K, C, P |
| Brain 0 | Today's rule as the starting point, e.g. SPT. | L, BF |
| Rule / heuristic | A hand-written decision rule. | K, C, P |
| SPT | "Shortest processing time first": the rule in the production cell. | K, L |
| EDF | "Earliest due date first": the rule in the big cell with three machines. | L |
| FIFO | "First in, first out." | K |
| Mean ± SD | Average and standard deviation over several seeds. | K, L |
| Paired seeds | Comparing two brains seed by seed. | L |
| Win / tie / loss | Counted per paired seed. | L |
| Winner's curse | The one that looks best on a small validation is often just lucky. | L |
| Noise | Random variation that can hide a difference or create a false one. | L |
| Success criterion / locked criterion | The requirement for success, written down before the code so the finish line cannot be moved. | K, L |
| MET / NOT MET | The criterion is met / not met. | K, L |
| Regression suite | Tests with locked results that catch it if anything changes (72 checks in 6.2). | K |
| Locked result / fingerprint | A number or a SHA hash that must come out exactly the same. | K, L |
| Get-VBAFTrace / trace | A step-by-step record of one episode. | K, C |
| Dry run | A small run proving the machinery works before the real one. | K, L |

## 11. Failure modes and kernel findings

| Term | Meaning | Where |
| --- | --- | --- |
| Kernel findings (KF-1 to KF-15) | Kernel bugs found in the Lab, numbered and documented. Most are fixed. | K, L |
| Collapse | When a brain picks one action regardless of state. | L |
| Unstable learning | When the policy jumps between fixed actions during training. | L |
| Dead network | A network where saturated neurons no longer learn. | L |
| Reward design | How the reward is put together. Poor design can teach the wrong things. | K, L |
| Reward hacking | When the agent finds a way to collect reward without solving the task. | L |
| Live data | Data from the real PC (system log, CPU, clock), which makes results unreproducible (KF-7, KF-15). | K, L |
| LiveMode / -Live | Switches live data on. Without it the environment is simulated. | K |
| SimMode | Training on simulated data. | K |
| Aliasing (shared arrays) | When two networks point at the same weights in memory (KF-13). | K, L |

## 12. Worlds and pillars

| Term | Meaning | Where |
| --- | --- | --- |
| Pillar | One of the kernel's 26 enterprise agents, each with its own environment and training function. | K |
| Enterprise pillar | A pillar for an IT operations task (e.g. AlertRouter, SelfHealing). | K |
| Environment group | Pillars that share the same environment under different names (KF-5: 26 pillars, 11 environments). | K |
| New-EnterpriseEnvironment | The kernel's factory for the 4 enterprise environments. | K |
| AlertRouter | Pillar that routes events to ignore, log, alert or escalate. | K |
| JobScheduler | Pillar that decides whether a job should run, wait or be skipped. | K |
| ResourceOptimizer | Pillar that scales resources down, keeps them normal or scales them up. | K |
| SupplyChain | Pillar that orders goods for a warehouse. | K |
| AutoPilot | Pillar that chooses an intervention level from 4 simulated signals. Does not read the other pillars (KF-11). | K |
| The production cell | The Lab world: one machine, an order queue with due dates. Now part of the kernel. | K, L |
| Shift | One episode in the production cell. | K, L |
| Order queue / due date / tardiness | The orders waiting, when they must be finished, and how late they end up. | K, L |
| BigCell | The larger Lab world with three machines, downtime and an energy price (phase 6). | L |
| CartPole / GridWorld / RandomWalk | The kernel's classic practice environments. | K |
| Castle Learning | The kernel example where a Q-agent learns to build varied castles. | K |
| Market simulation | The kernel example with competing company agents. | K |
| Multi-agent | Several agents in the same environment. | K |
| Federated learning | Training spread over several sites where only the model is shared, not the data. | K |
| Nash equilibrium | A state where no agent can improve by changing its strategy alone. | K |

## 13. VBAF-Center

The explanations in this section are based on function names and earlier discussions, not on a review of Center's code. Corrections are welcome where the meaning differs.

| Term | Meaning | Where |
| --- | --- | --- |
| Signal | A measured value from the customer's system, e.g. the number of late orders. | C, P |
| Signal colour / signal status | The traffic light for a signal: green, yellow or red. | C |
| Threshold | The limit where a signal changes colour or triggers an action. | C, P |
| Threshold check | Checking the signals against the thresholds. | C |
| Suggested threshold / range | A threshold the system suggests based on history. | C |
| Action threshold | The limit for when an action is suggested or carried out. | C |
| Action map | The mapping between signals and actions. | C |
| Agent map | The mapping between the customer's tasks and agents. | C |
| Classification | Putting a situation into a category. | C, P |
| Routing / router | Sending a situation to the right action or agent. | C, P |
| Escalation | Passing a case on to a person or a higher level. | C |
| Normalization | Converting the customer's data to a common scale. | C |
| Normalization report | A report on how the data was normalized. | C |
| Interpretation | Turning raw data into an understandable situation. | C |
| Write-back | Writing an action back into the customer's system. | C |
| Undo write-back | Rolling back an action that was written back. | C |
| Auto-connect | Automatic connection to the customer's system. | C |
| API inspector | A tool that examines an API and its fields. | C |
| JSON flattening | Turning nested data into a flat list of fields. | C |
| TMS | Transport Management System: the customer's transport planning system. | C |
| Fake TMS | A test system that behaves like a real TMS. | C |
| Day replay | Playing back a whole day's events. | C |
| Time curve / day modifier | How activity varies over the day and the week in the simulation. | C |
| Event | A single thing that happens in the simulation or at the customer. | C |
| Learning from history | Adjusting thresholds and suggestions based on earlier runs. | C |
| Learning report | A report on what the system has learned. | C |
| AI prompt / AI provider / AI key | The text sent to a language model, which model is used, and the access key. | C |
| Claude brain | Center's use of a language model as an adviser. Not a brain in the Brain Factory sense. | C |
| Override | When a person overrules the system's suggestion. | C |
| Override context / history | The background for, and the list of, human overrides. | C |
| Action explanation | The system's reasoning for a suggested action. | C |
| Onboarding | Setting up a new customer. | C |
| Assessment | Evaluating a customer's needs and complexity. | C |
| Crisis tree | A decision plan for what should happen in a crisis. | C |
| Daily briefing | The daily summary for the customer. | C |
| Portal | The customer's web page with status and actions. | C |
| Dashboard / KPI | Overview page / key figures. | C, P |
| Schedule | When runs happen automatically. | C, P |
| PPO (in Center) | Appears in 13 files, but Center has no network classes. The meaning is unresolved and needs checking. | C |

## 14. VBAF-Platform

Here too the explanations are based on function names. Platform has at least two trained networks (disk failure and network anomaly) with a sanity gate.

| Term | Meaning | Where |
| --- | --- | --- |
| Trained model | A network that has been trained and saved, e.g. the disk model and the network model. | P |
| Model export / import | Saving a trained model and loading it again. | P |
| Sanity gate | A quality gate that rejects a model if it does not behave sensibly. A step towards Brain Factory's final test. | P |
| Routed sample / routed models | Training samples and models split by type, so each group gets its own model. | P |
| Live features | Properties measured on the real machine right now. | P |
| Disk failure probability | The model's estimate of how likely a disk is to fail. | P |
| Network anomaly probability | The model's estimate of how unusual the current network traffic is. | P |
| Predictive failure | Predicting a failure before it happens. | P |
| Health score / health weights | A single number for the condition of a machine or customer, and the weights for what counts. | P |
| Customer health | The health score for a whole customer. | P |
| Business priority | How important a machine or case is to the business. | P |
| Risk profile / fleet risk | The overall risk of a customer or of the whole fleet. | P |
| Change risk | The risk of a planned change. | P |
| Patch safety score / patch urgency signal | How safely an update can be installed, and how urgent it is. | P |
| Baseline | A machine's normal state, which deviations are measured against. | P |
| Configuration drift | When a configuration moves away from what is expected over time. | P |
| Documentation drift | When reality no longer matches the documentation. | P |
| Flag | A marker on something that should be looked at. | P |
| Incident indicators | Signs that a security incident is under way. | P |
| IP reputation | How trusted an IP address is. | P |
| Remediation / remediation library | Fixing a problem, and the collection of known fixes. | P |
| Containment | Isolating an attacked machine. | P |
| Hardening | Making a machine more secure by closing weaknesses. | P |
| Threat hunting | Actively searching for signs of an attack. | P |
| Self-healing | The system fixing known faults by itself. | K, P |
| Safe agent run / agent result | Running an agent so a failure does not bring down the rest, and the result of the run. | P |
| Shadow IT | Software and services that IT does not know about. | P |
| License harvesting | Finding and freeing unused licences. | P |
| Lifecycle | A machine's age and stage from new to replacement. | P |
| Endpoint / inventory | A machine at the customer, and the list of them. | P |
| Nightly run | Platform's automatic run at night (currently switched off). | P |

## 15. MLOps, explainability and time series

| Term | Meaning | Where |
| --- | --- | --- |
| MLOps | Running models in production: versioning, deployment, monitoring and updating. | K |
| Model registry | A register of models and their versions. | K |
| Model server | A service that makes a model available to other programs. | K |
| Data pipeline | The chain of steps data goes through from source to model. | K |
| Data drift | When the data a model meets in production changes compared with the training data. | K |
| A/B test | Comparing two versions, each on its own group. | K |
| Canary | Rolling a new version out to a small share first. | K |
| Rollback | Going back to the previous version. | K, C, BF |
| Explainability | Being able to show why a model gave its answer. | K, C |
| SHAP | A method that splits an answer into the contributions of the individual features. | K |
| LIME | A method that explains one answer with a simple local model. | K |
| Feature importance / permutation importance | How much each feature matters, measured e.g. by shuffling it and seeing how much worse the answer gets. | K |
| Partial dependence | How the answer changes when one feature is varied. | K |
| Time series | Data measured over time. | K |
| Moving average | The average of the latest n measurements. | K |
| Seasonality | Repeating patterns over the day, week or year. | K, C |
| Forecast | A prediction of future values. | K, C |
| Anomaly | A measurement that deviates markedly from normal. | K, C, P |
| z-score | How many standard deviations a measurement lies from the mean. | K |
| Confidence | How sure a model or rule is of its answer. | C, P |

## 16. Architecture, Brain Factory and Agent Factory

| Term | Meaning | Where |
| --- | --- | --- |
| Kernel | VBAF itself: how learning is done. The one shared engine under all projects. | K |
| Brain | What has been learned: a trained network that has passed the final test and has a datasheet. | BF |
| Agent | One task in a domain, driven by a brain or a rule. | C, P |
| Application | What a person opens and uses (Center, Platform). | C, P |
| Sensor | The connection that reads the customer's data. | C, BF |
| Adapter | The translation between the customer's data and the brain's state. | C, P, BF |
| Guardrail | Limits a brain must never cross, e.g. a rush order may not wait more than 2 hours. | C, BF |
| Emergency stop | Being able to stop an agent immediately. | BF |
| Decision support | A system that suggests and explains while the person decides. | C |
| Simulator | A model of reality that a brain can practise in. | C, BF |
| Brain Factory | The workshop that produces a tested brain from an order, or gives an honest rejection. | BF |
| Agent Factory | The assembly line that gives an approved brain senses, hands and a job. | BF |
| Order form | The customer's description of the capability: what can be seen, what may be done, what counts as good, today's rule and the guardrails. | BF |
| Capability | What the customer orders, e.g. "can schedule production". | BF |
| World template | A reusable type of world: queue, scheduling, inventory, maintenance. | BF |
| Brain contract | The shared agreement on what a brain file contains and how it is used. | BF |
| Datasheet | The brain's product label: capability, final test, improvement over the rule, and limits. | BF |
| Approved brain | A brain that has passed the final test against the rule. | BF |
| Honest rejection | The factory's answer when no brain beats the rule: keep the rule. A feature, not a failure. | BF |
| Packaging | Bundling brain, settings and datasheet according to the brain contract. | BF |
| Import-VBAFBrain / Install-VBAFBrain | Planned commands for loading and installing a packaged brain. | BF |
| OrderSequencer v1 | Proposed name for the first approved brain: picks the next order on one machine. | L, BF |
| The apprentice | How a brain is put into service: handles the routine, asks when in doubt, learns from the answer. | C, BF |
| Shadow mode | Apprentice stage 1: the brain suggests, the person decides, and both are logged. | BF |
| Monitoring in production | Continuously measuring whether the brain still beats the rule. | BF |
| Fallback to the rule | Switching back to the rule when the brain is no longer the best. | BF |
| Versioning | Keeping track of the brains' versions. | BF |

## 17. Words with two meanings

| Word | Meaning 1 | Meaning 2 | Use here |
| --- | --- | --- | --- |
| Brain | A trained network with a final test and a datasheet (Brain Factory) | A language model acting as adviser ("Claude brain" in Center) | Brain = the Brain Factory meaning; write "language model" for the other |
| Kernel | The VBAF kernel (the framework) | The filter in a CNN | Write "filter" for the CNN meaning |
| Shadow | Shadow mode: the brain suggests, the person decides | Shadow IT: software that IT does not know about | Always write the full term |
| Drift | Data drift: the data a model meets changes over time | Configuration / documentation drift (Platform) | Say which kind |
| Agent | A task driven by a brain or a rule (architecture) | The RL agent that learns in an environment | Context decides; both are correct |
| Normalization | Scaling data to 0-1 (training) | Converting the customer's data to a common form (Center) | Both are correct; say which |
| Evolution | Genetic algorithm / PBT (Lab) | How VBAF has developed over time | Use only for the Lab method |
| Encoder | The compressing part of an autoencoder | A converter from categories to numbers | Context decides |
| Baseline | The bar a brain must beat | A machine's normal state (Platform) | Write "the bar" for the first |
| PPO | The algorithm Proximal Policy Optimization (kernel, Platform) | Unresolved use in 13 Center files | Needs checking |
