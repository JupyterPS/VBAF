#Requires -Version 5.1
<#
.SYNOPSIS
    Experience Replay Memory Buffer
.DESCRIPTION
    Stores and samples past experiences for reinforcement learning.

    WHAT YOU ARE LEARNING HERE:
    ============================
    Experience Replay is one of the two key innovations that made DQN work.
    Without it, training a neural network on reinforcement learning data
    is highly unstable. With it, training becomes dramatically more stable.

    THE PROBLEM IT SOLVES:
    ======================
    In reinforcement learning, experiences arrive in SEQUENCE:
      step 1: cart moves left, pole tilts left
      step 2: cart moves left, pole tilts more left
      step 3: cart moves left, pole falls

    If we train the neural network on these experiences in order,
    we are training on highly CORRELATED data. The network overfits
    to recent experiences and forgets earlier ones.

    This is called "catastrophic forgetting" -- and it causes training
    to diverge (get worse over time instead of better).

    THE SOLUTION:
    =============
    Store ALL experiences in a buffer (this class).
    At each training step, sample a RANDOM BATCH from the buffer.

    Random sampling breaks the correlation between consecutive experiences.
    The network sees a diverse mix of old and new experiences each step.
    This is the same principle as shuffling a deck of cards before dealing.

    CIRCULAR BUFFER:
    ================
    When the buffer is full (MaxSize reached), the OLDEST experience
    is removed to make room for the newest one.
    This keeps memory usage bounded and ensures the agent trains on
    relatively recent experiences -- not experiences from the very
    start of training when it knew nothing.

    THEORY REFERENCE:
    =================
    Lin, L.J. (1992). "Self-improving reactive agents based on reinforcement
    learning, planning and teaching." Machine Learning, 8(3-4), 293-321.

    Experience replay was first proposed by Lin in 1992 -- over 20 years
    before DQN made it famous. DeepMind combined it with neural networks
    and target networks to create the DQN breakthrough.

.NOTES
    Part of VBAF (Visual AI & Reinforcement Learning Framework)
    Educational use -- read the comments, not just the code.
    Used by: VBAF.RL.DQN.ps1
#>

class ExperienceReplay {

    # The buffer -- stores experiences as hashtables
    # Each experience: @{ State; Action; Reward; NextState; Done }
    [System.Collections.ArrayList]$Memory

    # Maximum number of experiences to store
    # When full, oldest experience is removed (circular buffer)
    [int]$MaxSize

    # Constructor: create an empty buffer with a fixed capacity
    # Typical sizes: 10,000 to 1,000,000 depending on problem complexity
    # Larger buffer = more diverse samples = more stable training
    # Smaller buffer = faster (less memory) but may forget early experiences
    ExperienceReplay([int]$maxSize) {
        $this.Memory  = New-Object System.Collections.ArrayList
        $this.MaxSize = $maxSize
    }

    # Add one experience to the buffer.
    # An experience is a (state, action, reward, nextState, done) tuple --
    # everything the agent needs to learn from one environment step.
    #
    # CIRCULAR BUFFER BEHAVIOUR:
    # --------------------------
    # When Memory.Count > MaxSize, remove the oldest experience (index 0).
    # This is a FIFO (First In, First Out) queue with a fixed size.
    # The oldest experiences are least relevant -- the agent has improved
    # since then and those early random experiences are less useful.
    [void] Add([hashtable]$experience) {
        $this.Memory.Add($experience) | Out-Null

        if ($this.Memory.Count -gt $this.MaxSize) {
            $this.Memory.RemoveAt(0)   # Remove oldest -- make room for newest
        }
    }

    # Sample a random batch of experiences for training.
    #
    # WHY RANDOM SAMPLING?
    # --------------------
    # Consecutive experiences are highly correlated -- the same state
    # appears in slightly different forms across adjacent steps.
    # Training on sequences like this causes the network to overfit
    # to recent patterns and destabilises learning.
    #
    # Random sampling ensures each training batch contains a diverse
    # mix of experiences from different times and situations.
    # This is the core benefit of experience replay.
    #
    # UNIQUE INDICES:
    # ---------------
    # We track used indices to avoid sampling the same experience twice
    # in one batch. With up to 10 collision attempts per sample, this
    # works well in practice without being computationally expensive.
    [hashtable[]] Sample([int]$batchSize) {
        if ($this.Memory.Count -eq 0) {
            return @()
        }

        # Cannot sample more than we have
        $actualSize  = [Math]::Min($batchSize, $this.Memory.Count)
        $samples     = New-Object System.Collections.ArrayList
        $usedIndices = @{}

        for ($i = 0; $i -lt $actualSize; $i++) {
            # Pick a random index -- retry if already used (avoid duplicates)
            $index    = Get-Random -Minimum 0 -Maximum $this.Memory.Count
            $attempts = 0
            while ($usedIndices.ContainsKey($index) -and $attempts -lt 10) {
                $index = Get-Random -Minimum 0 -Maximum $this.Memory.Count
                $attempts++
            }

            $usedIndices[$index] = $true
            $samples.Add($this.Memory[$index]) | Out-Null
        }

        return $samples.ToArray()
    }

    # Current number of experiences stored.
    # Training cannot begin until Size() >= BatchSize.
    # This is why DQN waits before calling Replay().
    [int] Size() {
        return $this.Memory.Count
    }

    # Empty the buffer -- used when resetting an agent completely.
    [void] Clear() {
        $this.Memory.Clear()
    }

    # True when the buffer has reached its maximum capacity.
    # At this point every new experience evicts the oldest one.
    [bool] IsFull() {
        return $this.Memory.Count -ge $this.MaxSize
    }
}

# ============================================================================
# QUICK REFERENCE
# ============================================================================
#
# CREATE A BUFFER:
#   $memory = [ExperienceReplay]::new(10000)   # store up to 10,000 experiences
#
# ADD AN EXPERIENCE:
#   $memory.Add(@{
#       State     = @(0.1, 0.0, 0.05, 0.0)
#       Action    = 1
#       Reward    = 1.0
#       NextState = @(0.12, 0.03, 0.06, 0.01)
#       Done      = $false
#   })
#
# SAMPLE A BATCH FOR TRAINING:
#   if ($memory.Size() -ge 32) {
#       $batch = $memory.Sample(32)
#       foreach ($exp in $batch) {
#           # Train on: $exp.State, $exp.Action, $exp.Reward, $exp.NextState, $exp.Done
#       }
#   }
#
# CHECK BUFFER STATUS:
#   $memory.Size()    # how many experiences stored
#   $memory.IsFull()  # true when MaxSize reached
#
# SEE ALSO:
#   VBAF.RL.DQN.ps1  -- uses this buffer in the Replay() method
# ============================================================================