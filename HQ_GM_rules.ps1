WHAT THE GAME MACHINE HANDLES vs. WHAT YOU HANDLE

🎮 GAME MACHINE (GM) HANDLES ✅

Automatic Features - You Don't Touch These
1. Master Timer Loop

✅ Single 50ms interval timer for entire dashboard
✅ Calls OnUpdate() on ALL active shows every frame
✅ Starts automatically when dashboard loads
✅ Stops automatically on shutdown
✅ You NEVER create timers in V2 shows

2. Show Lifecycle Management

✅ Calls OnStart() when show becomes visible
✅ Calls OnUpdate() every frame (20 FPS)
✅ Calls OnStop() when switching to another show
✅ Tracks which show is currently active
✅ Guarantees cleanup - OnStop() always runs

3. Show Registry

✅ RegisterShow() - Adds shows to the system
✅ LoadShow() - Activates a show by name
✅ StopAll() - Emergency cleanup on shutdown
✅ Maintains Shows dictionary with all V2 shows

4. Company Integration

✅ SetCompany() - Links show to company data
✅ GetCompanyMetrics() - Returns company info
✅ Provides company data to shows automatically

5. State Management

✅ Tracks if show is running (IsRunning property)
✅ Prevents double-initialization
✅ Handles show transitions cleanly
✅ No manual state tracking needed

6. Error Handling

✅ Try-catch around all lifecycle calls
✅ Logs errors without crashing dashboard
✅ Continues running other shows if one fails

_________________________________________________________________

# What You Implement in Each Show Class
# 1. Properties (Your Data)

hidden [hashtable] $State          # Your show's state
hidden [ArrayList] $Items          # Your collections
hidden [Panel] $Canvas             # Your UI controls
hidden [Button] $MyButton          # Your buttons, sliders, etc.

❌ DO NOT create Timer properties
✅ DO create data structures you need

_____________________________________________

# 2. Constructor (Initialization)

ShowX($panel) : base("showX", $panel) {
    $this.State = @{ Counter = 0 }  # Your initial data
    $this.Items = [ArrayList]::new()
}

✅ Initialize your state/data
✅ Create empty collections
❌ DO NOT create timers or start animations

______________________________________________

# 3. OnStart() - UI Setup

[void] OnStart() {
    $this.Panel.Controls.Clear()
    $this.CreateCanvas()           # Your method
    $this.CreateControls()         # Your method
    $this.SetupPaintEvent()        # Your method
    $this.AttachEventHandlers()    # Your method
}

✅ Create UI elements (buttons, panels, labels)
✅ Setup Paint events
✅ Attach event handlers (with $self = $this)
✅ Initialize visual state
❌ DO NOT create or start timers

______________________________________________

# 4. OnUpdate() - Animation Logic

[void] OnUpdate() {
    $this.State.Counter++          # Update counters
    foreach ($item in $this.Items) {
        $item.X += $item.VX        # Update positions
    }
    $this.Canvas.Invalidate()      # Trigger repaint
}

✅ Update animation state
✅ Move objects/particles
✅ Update counters/timers
✅ Call .Invalidate() to trigger Paint
✅ This runs automatically every 50ms

_____________________________________________

# 5. OnStop() - Cleanup

[void] OnStop() {
    $this.Items.Clear()                    # Clear collections
    $this.Canvas.Remove_Paint($null)       # Remove handlers
    $this.MyButton.Remove_Click($null)     # Remove handlers
    $this.Panel.Controls.Clear()           # Clear UI
    $this.State.Counter = 0                # Reset state
}

✅ Clear your collections
✅ Remove your event handlers
✅ Clear your UI controls
✅ Reset your state
❌ DO NOT stop/dispose timers (there arent any!)

____________________________________________

# 6. Helper Methods (Your Logic)

hidden [void] CreateCanvas() { ... }
hidden [void] CreateControls() { ... }
hidden [void] SetupPaintEvent() { ... }     # Needs $self = $this
hidden [void] AttachEventHandlers() { ... } # Needs $self = $this
hidden [void] RenderFrame($g) { ... }

✅ Organize your code into methods
✅ Use hidden for private methods
✅ Use $self = $this in event handlers

____________________________________________

# 7. Event Handlers (UI Interaction)

hidden [void] AttachEventHandlers() {
    $self = $this  # CRITICAL!
    
    $this.MyButton.Add_Click({
        param($sender, $args)
        $self.State.Counter++      # Use $self!
    }.GetNewClosure())
}

✅ ALWAYS use $self = $this pattern
✅ Access class via $self, not $this
✅ Use param($sender, $args)
✅ End with .GetNewClosure()

___________________________________________

# 8. Rendering Logic (Paint Event)

hidden [void] RenderFrame([Graphics]$g) {
    $g.Clear([Color]::Black)
    foreach ($item in $this.Items) {
        // Draw item
    }
}

✅ All your drawing code
✅ Use $this here (not in event, so its safe)
✅ Access $this.State, $this.Items, etc.

____________________________________________

 KEY RULES TO REMEMBER
❌ NEVER Do These in V2 Shows:

Create System.Windows.Forms.Timer
Call .Start() or .Stop() on timers
Add .Add_Tick() handlers
Use $Global:ShowXTimer
Manually track $Global:ShowXBuilding state
Switch show visibility yourself

✅ ALWAYS Do These:

Inherit from BaseShow
Call : base("showX", $panel) in constructor
Implement OnStart(), OnUpdate(), OnStop()
Use $self = $this in event handlers
Call .Invalidate() to trigger Paint
Clear collections in OnStop()
Remove event handlers in OnStop()

____________________________________________

📋 CONVERSION CHECKLIST
When converting a show, ask yourself:

 Did I delete all Timer creation code?
 Did I move Timer Tick code to OnUpdate()?
 Did I add $self = $this to all event handlers?
 Did I replace $Global:ShowXData with $this.State?
 Did I implement all three lifecycle methods?
 Did I test that cleanup works (switch shows)?