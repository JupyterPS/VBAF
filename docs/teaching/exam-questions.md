# Exam Questions
Assessment questions for the VBAF ML programme.
Grouped by topic and difficulty level.

## Neural Networks

**Beginner**
1. What is the purpose of the activation function in a neural network?
2. What does backpropagation compute, and why is it necessary?
3. Why can a single-layer perceptron not solve the XOR problem?

**Intermediate**
4. Explain the vanishing gradient problem and how it affects deep networks.
5. What is the difference between a learning rate of 0.001 and 0.1?
   When would you choose each?

**Advanced**
6. A neural network trained on XOR converges in some runs but not others.
   The architecture and learning rate are fixed. Explain why this happens
   and describe two strategies to improve convergence reliability.

## Supervised Learning

**Beginner**
7. What is the difference between classification and regression?
8. What does an R2 score of 0.95 mean?
9. Why should you always scale features before training a Ridge regression model?

**Intermediate**
10. What is data leakage and how does it affect model evaluation?
11. Explain cross-validation. Why is it better than a single train/test split?
12. When would you use Ridge over Linear regression?

**Advanced**
13. You train a LinearRegression model on house price data and get R2=0.97
    on the training set but R2=0.61 on the test set.
    Diagnose the problem. List three concrete steps to fix it using VBAF tools,
    naming the specific classes or functions you would use.

## Reinforcement Learning

**Beginner**
14. Define: state, action, reward, policy.
15. What is epsilon-greedy exploration?
16. What is the difference between Q-learning and DQN?

**Intermediate**
17. Why does DQN use a target network?
    What problem does it solve?
18. What is experience replay and why does random sampling matter?
19. A DQN agent always picks action 0 after training.
    What likely went wrong?

**Advanced**
20. Compare Q-learning and DQN on the Castle Learning problem.
    Q-learning uses a hashtable; DQN uses a neural network.
    For this specific problem (8 castle types, sequence-based state),
    which approach is more appropriate and why?
    What would happen if you scaled to 100 castle types?

21. A DQN agent trains for 500 episodes. Baseline reward is -40.
    At episode 100 the average reward is -38. At episode 500 it is -36.
    The agent is still mostly exploring (epsilon = 0.3).
    Identify two problems and propose specific hyperparameter changes
    using the VBAF DQNConfig parameters to fix them.

## Multi-Agent Systems

**Beginner**
22. What is the difference between single-agent and multi-agent
    reinforcement learning?
23. In the VBAF market simulation, four companies learn simultaneously.
    Why is this harder than training one agent alone?

**Intermediate**
24. Define non-stationarity in multi-agent RL.
    Why does it make convergence harder to guarantee?
25. The market simulation sometimes produces tacit collusion --
    companies converge on similar prices without communicating.
    Explain why Q-learning agents produce this emergent behaviour.

**Advanced**
26. In the VBAF market simulation, MarketLeader starts with 15% market share
    and 1,500,000 capital. After 10 years it still leads.
    Design a modified starting condition that gives StartupX (800,000 capital)
    a realistic chance of winning by year 10.
    Justify your changes using RL theory -- not just intuition.

## Enterprise Automation

**Beginner**
27. What does SimMode do in VBAF enterprise functions?
28. What is the significance of the 15/40/30/15 distribution?

**Intermediate**
29. Why does VBAF use 4 state signals and 4 actions for every enterprise pillar?
    What would happen if you used 10 state signals instead?
30. An enterprise DQN agent trains for 100 episodes.
    Baseline reward: -30. Trained reward: -28. Improvement: 6.7%.
    Is this a success? What would you change to improve the result?

**Advanced**
31. Design an enterprise pillar for a hospital bed management system.
    Define: 4 state signals, 4 actions, reward function, expected improvement.
    Justify each design decision.

32. You have built a custom enterprise pillar that works well in SimMode
    (improvement +80%) but performs poorly on real Windows data (improvement +5%).
    List three likely causes and describe how you would diagnose and fix each one,
    referencing specific VBAF functions or design patterns.

## ML Pipeline

**Intermediate**
33. You receive a CSV with 1,000 rows and 20 columns.
    Three columns have missing values. Two columns are categorical.
    Write the complete VBAF preprocessing pipeline in PowerShell,
    naming each class used and explaining why each step is needed.

**Advanced**
34. A colleague runs Invoke-VBAFAutoML and gets R2=0.99.
    They claim the model is production-ready.
    List three questions you would ask before accepting this claim,
    and describe what VBAF tools you would use to verify each answer.