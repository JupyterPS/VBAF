                                                                                                                                                     <#
                                                   - oo00oo -  
                                              
                                                     G U I        
                                              
                                               M A C H I N E  R O O M  
                                               
                                               (Qualified staff only) 
                                                                                                                                                      #>



# 15. User Interfaces (GUIs)


  # PowerShell can create graphical user interfaces (GUIs) using Windows Forms or Windows Presentation Foundation (WPF).
  # This allows for more interactive scripts and applications.
  # GUI elements can include buttons, text boxes, and labels.

       Add-Type -AssemblyName System.Windows.Forms
       $form = New-Object System.Windows.Forms.Form
       $button = New-Object System.Windows.Forms.Button
       $button.Text = "Click Me"
       $button.Add_Click({ Write-Host "Button clicked!" })
       $form.Controls.Add($button)
       $form.ShowDialog()


# Jump directly to one of the below topics. Activate (run selected lines - pf8) at top left

. "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Jump.ps1"  
$Num = 15
Jump-To-GUISectionISE -Num $Num 


<###################################################################################################

Powershell GUI Forms and Components - 01 A Basic Windows Form 
Powershell GUI Forms and Components - 02 Drawing Directly Onto a Form 
Powershell GUI Forms and Components - 03 Adding Components to a Form 
Powershell GUI Forms and Components - 04 Adding Groupboxes to a Form 
Powershell GUI Forms and Components - 05 Adding a ListBox to a Form 
Powershell GUI Forms and Components - 06 Adding ComboBoxes to a Form 
Powershell GUI Forms and Components - 07 Adding Masked TextBoxes to a Form 
Powershell GUI Forms and Components - 08 Adding a PictureBox to a Form 
Powershell GUI Forms and Components - 09 Adding Checkboxes to a Form Handling the CLICK Event 
Powershell GUI Forms and Components - 10 Adding Checkboxes to a Form Handling the Selected Event
Powershell GUI Forms and Components - 11 Adding a ProgressBar to a Form 
Powershell GUI Forms and Components - 12 Adding a DataGridView to a Form 
Powershell GUI Forms and Components - 13 Adding Panels to a Form 
Powershell GUI Forms and Components - 14 Adding Menus to a Form 

###################################################################################################>



# Powershell GUI Forms and Components - 01 A Basic Windows Form                          
# Author: Carly Salali Germany
# Date: 08/04/2020



# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;

# 3. Set Size of Form
#-----------------------------------------------------------------------------------------
$Form_MAIN.ClientSize = New-Object System.Drawing.Point(350,350);

# 4. Set Position of Form
#-----------------------------------------------------------------------------------------
$Form_MAIN.StartPosition = "manual"; #or "CenterScreen"
$Form_MAIN.Location = New-Object System.Drawing.Size(800,300);

# 5. Set Title Text for Top Label of Form
#-----------------------------------------------------------------------------------------
$Form_MAIN.text = "Carly the Sparkly Unicorn";
$Form_MAIN.TopMost = $false;

# 6. Set Form Background Color
#-----------------------------------------------------------------------------------------
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");

# 7. Display the Form
#-----------------------------------------------------------------------------------------
# Note: Using ShowDialog() locks up ISE after form closes sometimes. So trying an alternative:
#[system.windows.forms.application]::run($form)

$Form_MAIN.ShowDialog();
#[system.windows.forms.application]::run($Form_MAIN);
#########################################################################################################################

# Powershell GUI Forms and Components - 02 Drawing Directly Onto a Form
# Author: Carly Salali Germany
# Date: 08/04/2020



#<###################################################################################################

# GDI Graphics Mehods You Can Use to Draw Directly Onto a Form

 
# Note: To draw directly on a FORM with Graphics methods, you must:

# 1. Call the CreateGraphics() on the form itself:

        $GRAPH = $Form_MAIN.CreateGraphics();

# 2. Override your own version of the EVENT HANDLER add_paint:

            $Form_MAIN.add_paint(
            {
                 $A_Brush = New-Object Drawing.SolidBrush("PINK");
                 $GRAPH.FillEllipse($A_Brush,150,150,180,180);
            })

# The vector graphics functions below must be called from insde the 
# event handler when a Window Form is painted/refreshed. 
 

####################################################################################################

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize = New-Object System.Drawing.Point(350,365);
$Form_MAIN.StartPosition = "manual"; #or "CenterScreen"
$Form_MAIN.Location = New-Object System.Drawing.Size(800,300);
$Form_MAIN.text = "Carkly the Sparkly Unicorn";
$Form_MAIN.TopMost = $false;
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#bd10e0");

# 3. Get a Pointer to the Form Background to Draw Graphics On 
#-----------------------------------------------------------------------------------------
$GRAPH = $Form_MAIN.CreateGraphics();


# 4. OVERRIDE the Form add_paint() Event Handler
#-----------------------------------------------------------------------------------------
$Form_MAIN.add_paint(
{
          # Draw_Filled_Rectangles;
          # Draw_Empty_Rectangles;
           Draw_Lines;
          # Draw_A_Bezier_Curve;
          # Draw_Ellipses;
          # Draw_String_Message;
})


# 5. Draw Some Things Directly Onto the Form
#-----------------------------------------------------------------------------------------

function Draw_A_Bezier_Curve
{
         $A_Pen = New-Object Drawing.Pen("BLACK");
         $A_Pen.Color = "RED";
         $A_Pen.Width = 10;
         $p1 = New-Object Drawing.Point(10,100);
         $p2 = New-Object Drawing.Point(100,10);
         $p3 = New-Object Drawing.Point(170,170);
         $p4 = New-Object Drawing.Point(200,100);
         $GRAPH.DrawBezier($A_Pen,$p1,$p2,$p3,$p4);
}

#-----------------------------------------------------------------------------------------

function Draw_Lines
{
         $A_Pen = New-Object Drawing.Pen("BLACK");
         $A_Pen.Color = "BLUE";
         $A_Pen.Width = 10;
         $GRAPH.DrawLine($A_Pen,50,50,300,300);
         $GRAPH.DrawLine($A_Pen,300,50,50,300);
}

#-----------------------------------------------------------------------------------------

function Draw_Ellipses
{
         $A_Brush = New-Object Drawing.SolidBrush("PINK");
         #Two Different Ways
         $RECTANGLE = New-Object Drawing.Rectangle(10,10,180,180);
         $GRAPH.FillEllipse($A_Brush, $RECTANGLE);
         $GRAPH.FillEllipse($A_Brush,150,150,180,180);
}

#-----------------------------------------------------------------------------------------

function Draw_Filled_Rectangles
{
         $A_Brush = New-Object Drawing.SolidBrush("BLACK");
         $GRAPH.FillRectangle($A_Brush,75,75,100,100);
         $GRAPH.FillRectangle($A_Brush,200,200,100,100);
}

#-----------------------------------------------------------------------------------------

function Draw_Empty_Rectangles
{
         $A_Pen = New-Object Drawing.Pen("BLACK");
         $A_Pen.Width = 10;
         $GRAPH.DrawRectangle($A_Pen,75,75,100,100);
         $GRAPH.DrawRectangle($A_Pen,200,200,100,100);
}

#-----------------------------------------------------------------------------------------

function Draw_String_Message
{
         [String] $Message = "A long, LONG time ago ... `r`n" + 
                             "In a galaxy far, FAR away ... `r`n" +
                             "It was a DARK and STORMY night ...`r`n`r`n" + 
                             "And once upon a time?`r`n" +
                             "There was a magical UNICORN!`r`n" +
                             "And she was so totally SPARKLY!`r`n`r`n" + 
                             "And all her reindeer pals?`r`n" + 
                             "They did NOT want to play with her.`r`n" +
                             "Cause she was just WAAAYYYYY `r`n" + 
                             "too sparkly for them.`r`n`r`n" + 
                             "THE END";

         $A_Font = New-Object System.Drawing.Font("Comic Sans MS", 12);
         $A_Brush = New-Object Drawing.SolidBrush("BLACK");
         $RECTANGLE = New-Object Drawing.RectangleF(40,20,300,325);
         $GRAPH.DrawString($Message,$A_Font,$A_Brush,$RECTANGLE);
}

#-----------------------------------------------------------------------------------------

# 6. Display the Form
#-----------------------------------------------------------------------------------------
# Note: Using ShowDialog() locks up ISE after form closes sometimes. So trying an alternative:
#[system.windows.forms.application]::run($form)

$Form_MAIN.ShowDialog();
#[system.windows.forms.application]::run($Form_MAIN);

#########################################################################################################################


# Powershell GUI Forms and Components - 03 Adding Components to a Form
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize = New-Object System.Drawing.Point(630,248);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.text = "Carkly is Sparkly Unicorn!";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$TB_Input = New-Object system.Windows.Forms.TextBox;
$TB_Input.multiline = $true;
$TB_Input.text = "INPUT";
$TB_Input.width = 392;
$TB_Input.height = 40;
$TB_Input.location = New-Object System.Drawing.Point(109,35);
$TB_Input.Font  = New-Object System.Drawing.Font('Callibri',10);

$B_ENTER = New-Object system.Windows.Forms.Button;
$B_ENTER.text = "ENTER";
$B_ENTER.width = 60;
$B_ENTER.height = 30;
$B_ENTER.location = New-Object System.Drawing.Point(273,83);
$B_ENTER.Font = New-Object System.Drawing.Font('Callibri',10);

$L_Name = New-Object system.Windows.Forms.Label;
$L_Name.text = "Name:";
$L_Name.AutoSize = $true;
$L_Name.width = 25;
$L_Name.height = 10;
$L_Name.location = New-Object System.Drawing.Point(216,153);
$L_Name.Font = New-Object System.Drawing.Font('Callibri',10);

$L_Name_Output = New-Object system.Windows.Forms.Label;
$L_Name_Output.AutoSize = $true;
$L_Name_Output.width = 75;
$L_Name_Output.height = 10;
$L_Name_Output.location = New-Object System.Drawing.Point(268,144);
$L_Name_Output.Font = New-Object System.Drawing.Font('Comic Sans MS',16);

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$Form_MAIN.controls.AddRange(@($TB_Input,$B_ENTER,$L_Name,$L_Name_Output));

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------
$B_ENTER.Add_Click({ $L_Name_Output.Text = $TB_Input.text;  })

# 6. Display the Form
#-----------------------------------------------------------------------------------------
$Form_MAIN.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################


# Powershell GUI Forms and Components - 04 Adding Groupboxes to a Form
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize = New-Object System.Drawing.Point(593,392);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.text = "Carly is Sparkly Unicorn!";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$GB_Top = New-Object system.Windows.Forms.Groupbox;
$GB_Top.height = 148;
$GB_Top.width = 375;
$GB_Top.text = "GB Top";
$GB_Top.location = New-Object System.Drawing.Point(105,30);

$RB_Option1 = New-Object system.Windows.Forms.RadioButton;
$RB_Option1.Text = "To Be?";
$RB_Option1.AutoSize  = $true;
$RB_Option1.width = 104;
$RB_Option1.height = 10;
$RB_Option1.location = New-Object System.Drawing.Point(32,54);
$RB_Option1.Font = New-Object System.Drawing.Font('Callibri',10);

$RB_Option2 = New-Object system.Windows.Forms.RadioButton;
$RB_Option2.Text = "Or NOT To Be?";
$RB_Option2.AutoSize = $true;
$RB_Option2.width = 104;
$RB_Option2.height = 10;
$RB_Option2.location = New-Object System.Drawing.Point(32,94);
$RB_Option2.Font = New-Object System.Drawing.Font('Callibri',10);

$TB_Top_Output = New-Object system.Windows.Forms.TextBox;
$TB_Top_Output.multiline = $true;
$TB_Top_Output.width = 188;
$TB_Top_Output.height = 116;
$TB_Top_Output.location = New-Object System.Drawing.Point(167,14);
$TB_Top_Output.Font = New-Object System.Drawing.Font('Comic Sans MS',27);

$GB_Bottom = New-Object system.Windows.Forms.Groupbox;
$GB_Bottom.height = 148;
$GB_Bottom.width = 375;
$GB_Bottom.text = "GB Bottom";
$GB_Bottom.location = New-Object System.Drawing.Point(105,216);

$L_Bottom_Output = New-Object system.Windows.Forms.Label;
$L_Bottom_Output.text = "";
$L_Bottom_Output.AutoSize  = $false;
$L_Bottom_Output.TextAlign = "MiddleCenter";
$L_Bottom_Output.width  = 300;
$L_Bottom_Output.height = 60;
$L_Bottom_Output.location = New-Object System.Drawing.Point(35,20);
$L_Bottom_Output.Font = New-Object System.Drawing.Font('Comic Sans MS',30);
$L_Bottom_Output.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#bd10e0");

$B_Enter = New-Object system.Windows.Forms.Button;
$B_Enter.text = "ENTER";
$B_Enter.width = 120;
$B_Enter.height = 42;
$B_Enter.location = New-Object System.Drawing.Point(130,90);
$B_Enter.Font = New-Object System.Drawing.Font('Callibri',15);
$B_Enter.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$B_Enter.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");

# 4. Add the Components to the Group Boxes
#-----------------------------------------------------------------------------------------
$GB_Top.controls.AddRange(@($RB_Option1,$RB_Option2,$TB_Top_Output));
$GB_Bottom.controls.AddRange(@($L_Bottom_Output,$B_Enter));

# 5. Add the Group Boxes to the Form
#-----------------------------------------------------------------------------------------
$Form_MAIN.controls.AddRange(@($GB_Top,$GB_Bottom));

# 6. Code the Event Handlers
#-----------------------------------------------------------------------------------------
$RB_Option1.Add_Click({ $TB_Top_Output.Text = "To BE?"; })
$RB_Option2.Add_Click({ $TB_Top_Output.Text = "Or NOT`r`nto be?"; })
$B_Enter.Add_Click({ $L_Bottom_Output.Text = "Hello World!"; })

# 7. Display the Form
#-----------------------------------------------------------------------------------------
$Form_MAIN.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################


# Powershell GUI Forms and Components - 05 Adding a ListBox to a Form
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_Main = New-Object system.Windows.Forms.Form;
$Form_Main.ClientSize = New-Object System.Drawing.Point(758,580);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_Main.text = "Form";
$Form_Main.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$LB_Input = New-Object system.Windows.Forms.ListBox;
$LB_Input.text = "listBox";
$LB_Input.width = 367;
$LB_Input.height = 180;
$LB_Input.location = New-Object System.Drawing.Point(203,60);
$LB_Input.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$LB_Input.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#4a4a4a");
$LB_Input.Font = New-Object System.Drawing.Font('Comic Sans MS',16);
$LB_Input.Items.Add("Twilight Sparkle");
$LB_Input.Items.Add("Fluttershy");
$LB_Input.Items.Add("Rainbow Dash");
$LB_Input.Items.Add("Apple Jack");
$LB_Input.Items.Add("Pinkie Pie");
$LB_Input.Items.Add("Rarity");

$TB_Output = New-Object system.Windows.Forms.TextBox;
$TB_Output.multiline = $true;
$TB_Output.text = "Output Goes HERE!";
$TB_Output.width  = 567;
$TB_Output.height = 224;
$TB_Output.location = New-Object System.Drawing.Point(102,320);
$TB_Output.Font = New-Object System.Drawing.Font('Comic Sans MS',30);
$TB_Output.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$TB_Output.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#9013fe");
$TB_Output.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center;

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$Form_Main.controls.AddRange(@($LB_Input,$TB_Output))

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------
function Do_Something
{
         $CHOICE = $LB_Input.GetItemText($LB_Input.SelectedItem);
         $TB_Output.Text = "`r`nPony of the Month is:`r`n" + $CHOICE;
}
#-----------------------------------------------------------------------------------------

$LB_Input.Add_Click({ Do_Something; })

#-----------------------------------------------------------------------------------------

# 6. Display the Form
#-----------------------------------------------------------------------------------------
$Form_Main.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################

 
# Powershell GUI Forms and Components - 06 Adding ComboBoxes to a Form
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_Main = New-Object system.Windows.Forms.Form;
$Form_Main.ClientSize = New-Object System.Drawing.Point(597,477);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_Main.text = "Carly is Unicorn";
$Form_Main.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$CB_Input = New-Object system.Windows.Forms.ComboBox;
$CB_Input.text = "The Final Five";
$CB_Input.width = 304;
$CB_Input.height = 105;
$CB_Input.location = New-Object System.Drawing.Point(141,55);
$CB_Input.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',15);
$CB_Input.Items.Add("Gaius Baltar");
$CB_Input.Items.Add("Commander Adama");
$CB_Input.Items.Add("Starbuck");
$CB_Input.Items.Add("Apollo");

$TB_Output = New-Object system.Windows.Forms.TextBox;
$TB_Output.multiline = $true;
$TB_Output.text = "Output Will Go HERE";
$TB_Output.width = 484;
$TB_Output.height = 256;
$TB_Output.location = New-Object System.Drawing.Point(55,189);
$TB_Output.Font = New-Object System.Drawing.Font('Comic Sans MS',25);
$TB_Output.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$TB_Output.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");
$TB_Output.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center;

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$Form_Main.controls.AddRange(@($CB_Input,$TB_Output));

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------
function Do_Something
{
         $CHOICE = $CB_Input.GetItemText($CB_Input.SelectedItem);
         $TB_Output.Text = "`r`nThe CYLON of the Month is:`r`n" + $CHOICE;
}
#-----------------------------------------------------------------------------------------

$CB_Input.Add_SelectedIndexChanged({ Do_Something; })

#-----------------------------------------------------------------------------------------

# 6. Display the Form
#-----------------------------------------------------------------------------------------
$Form_Main.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################


# Powershell GUI Forms and Components - 07 Adding Masked TextBoxes to a Form
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize  = New-Object System.Drawing.Point(597,477);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.text = "Carly is Unicorn";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$TB_Output = New-Object system.Windows.Forms.TextBox;
$TB_Output.multiline = $true;
$TB_Output.text = "`r`nENTER 20-digit into the`r`nMASKED textbox above.`r`n" +
                  "Note that because it is masked?`r`nIt will only take numbers.";
$TB_Output.TabStop = $false;
$TB_Output.width = 484;
$TB_Output.height = 256;
$TB_Output.location = New-Object System.Drawing.Point(55,189);
$TB_Output.Font = New-Object System.Drawing.Font('Comic Sans MS',20);
$TB_Output.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$TB_Output.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");
$TB_Output.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center;

#Note: A MaskedTextBox allows you to set the Mask attribute and control input
$MTB_Password = New-Object system.Windows.Forms.MaskedTextBox;
$MTB_Password.multiline = $false;
$MTB_Password.Mask = "00000000000000000000";
$MTB_Password.PasswordChar = "*";
$MTB_Password.TabStop = $true;
$MTB_Password.TabIndex = 0;
$MTB_Password.SelectionStart = 0;
$MTB_Password.SelectionLength = $MTB_Password.Text.Length;
$MTB_Password.width = 421;
$MTB_Password.height = 68;
$MTB_Password.location = New-Object System.Drawing.Point(79,32);
$MTB_Password.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',20);

$B_ENTER = New-Object system.Windows.Forms.Button;
$B_ENTER.text = "ENTER";
$B_ENTER.width = 386;
$B_ENTER.height = 67;
$B_ENTER.location = New-Object System.Drawing.Point(97,97);
$B_ENTER.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',20);
$B_ENTER.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$B_ENTER.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#d0021b");

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$Form_MAIN.controls.AddRange(@($TB_Output,$MTB_Password,$B_ENTER))

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------
$B_ENTER.Add_Click({ $TB_Output.Text = $MTB_Password.Text; })

# 6. Display the Form
#-----------------------------------------------------------------------------------------
$Form_Main.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################


# Powershell GUI Forms and Components - 08 Adding a PictureBox to a Form
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize  = New-Object System.Drawing.Point(390,425);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");
$Form_MAIN.text = "Carly is Unicorn";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$PB_View = New-Object system.Windows.Forms.PictureBox;
$PB_View.width = 337;
$PB_View.height = 263;
$PB_View.location = New-Object System.Drawing.Point(28,127);
$PB_View_File = (Split-Path -Parent $PSCommandPath) + "\Images\Alice.jpg";
$PB_View.imageLocation = $PB_View_File;
$PB_View.BorderStyle = 1;
$PB_View.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::zoom;

$B_View = New-Object system.Windows.Forms.Button;
$B_View.text = "VIEW";
$B_View.width = 179;
$B_View.height = 55;
$B_View.location = New-Object System.Drawing.Point(110,38);
$B_View.Font = New-Object System.Drawing.Font('Microsoft Sans Serif',25);
$B_View.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$B_View.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#bd10e0");

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$Form_MAIN.controls.AddRange(@($PB_View,$B_View))

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------
function Reveal_the_View
{
        $PB_View_File = (Split-Path -Parent $PSCommandPath) + "\Images\Wolf.jpg";
        $PB_View.imageLocation = $PB_View_File; 
}

#-----------------------------------------------------------------------------------------

$B_View.Add_Click({ Reveal_the_View; })

#-----------------------------------------------------------------------------------------

# 6. Display Form
#-----------------------------------------------------------------------------------------
$Form_Main.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################

# Powershell GUI Forms and Components - 09 Adding Checkboxes to a Form Handling  
 
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize  = New-Object System.Drawing.Point(390,425);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");
$Form_MAIN.text = "Carly is Unicorn";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$GB_Top = New-Object system.Windows.Forms.Groupbox;
$GB_Top.Height = 102;
$GB_Top.Width = 351;
$GB_Top.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$GB_Top.Font = New-Object System.Drawing.Font('Callibri',10);
$GB_Top.Text  = "GB Best Starship Captains of All Time";
$GB_Top.Location = New-Object System.Drawing.Point(20,24);

$CheckB_Kirk = New-Object system.Windows.Forms.CheckBox;
$CheckB_Kirk.text = "James T. Kirk";
$CheckB_Kirk.AutoSize = $false;
$CheckB_Kirk.width = 121;
$CheckB_Kirk.height = 16;
$CheckB_Kirk.location = New-Object System.Drawing.Point(24,37);

$CheckB_Janeway = New-Object system.Windows.Forms.CheckBox;
$CheckB_Janeway.text = "Kathryn Janeway";
$CheckB_Janeway.AutoSize = $false;
$CheckB_Janeway.width  = 132;
$CheckB_Janeway.height = 17;
$CheckB_Janeway.location = New-Object System.Drawing.Point(24,64);

$CheckB_Sisko = New-Object system.Windows.Forms.CheckBox;
$CheckB_Sisko.text = "Benjamin L. Sisko";
$CheckB_Sisko.AutoSize = $false;
$CheckB_Sisko.width = 136;
$CheckB_Sisko.height = 17;
$CheckB_Sisko.location = New-Object System.Drawing.Point(202,36);

$CheckB_Picard = New-Object system.Windows.Forms.CheckBox;
$CheckB_Picard.text = "Jean Luc Picard";
$CheckB_Picard.AutoSize = $false;
$CheckB_Picard.width = 127;
$CheckB_Picard.height = 17;
$CheckB_Picard.location = New-Object System.Drawing.Point(202,64);

$TB_Output = New-Object system.Windows.Forms.TextBox;
$TB_Output.multiline = $true;
$TB_Output.width = 339;
$TB_Output.height = 216;
$TB_Output.location = New-Object System.Drawing.Point(30,158);
$TB_Output.Font = New-Object System.Drawing.Font('Comic Sans MS',16);
$TB_Output.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$TB_Output.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$GB_Top.controls.AddRange(@($CheckB_Kirk,$CheckB_Janeway,$CheckB_Picard,$CheckB_Sisko));
$Form_MAIN.controls.AddRange(@($GB_Top,$TB_Output));

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------
$CheckB_Kirk.Add_Click({ $TB_Output.Text = "Best captain is " + $CheckB_Kirk.Text; })
$CheckB_Janeway.Add_Click({ $TB_Output.Text = "Best captain is " + $CheckB_Janeway.Text; })
$CheckB_Sisko.Add_Click({ $TB_Output.Text = "Best captain is " + $CheckB_Sisko.Text; })
$CheckB_Picard.Add_Click({ $TB_Output.Text = "Best captain is " + $CheckB_Picard.Text; })

# 6. Display Form
#-----------------------------------------------------------------------------------------
$Form_Main.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################


# Powershell GUI Forms and Components - 10 Adding Checkboxes to a Form Handling the Selected Event
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize  = New-Object System.Drawing.Point(390,425);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");
$Form_MAIN.text = "Carly is Unicorn";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$GB_Top = New-Object system.Windows.Forms.Groupbox;
$GB_Top.Height = 102;
$GB_Top.Width = 351;
$GB_Top.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$GB_Top.Font = New-Object System.Drawing.Font('Callibri',10);
$GB_Top.Text  = "GB Best Starship Captains of All Time";
$GB_Top.Location = New-Object System.Drawing.Point(20,15);

$CheckB_Kirk = New-Object system.Windows.Forms.CheckBox;
$CheckB_Kirk.text = "James T. Kirk";
$CheckB_Kirk.AutoSize = $false;
$CheckB_Kirk.width = 121;
$CheckB_Kirk.height = 16;
$CheckB_Kirk.location = New-Object System.Drawing.Point(24,37);

$CheckB_Janeway = New-Object system.Windows.Forms.CheckBox;
$CheckB_Janeway.text = "Kathryn Janeway";
$CheckB_Janeway.AutoSize = $false;
$CheckB_Janeway.width  = 132;
$CheckB_Janeway.height = 17;
$CheckB_Janeway.location = New-Object System.Drawing.Point(24,64);

$CheckB_Sisko = New-Object system.Windows.Forms.CheckBox;
$CheckB_Sisko.text = "Benjamin L. Sisko";
$CheckB_Sisko.AutoSize = $false;
$CheckB_Sisko.width = 136;
$CheckB_Sisko.height = 17;
$CheckB_Sisko.location = New-Object System.Drawing.Point(202,36);

$CheckB_Picard = New-Object system.Windows.Forms.CheckBox;
$CheckB_Picard.text = "Jean Luc Picard";
$CheckB_Picard.AutoSize = $false;
$CheckB_Picard.width = 127;
$CheckB_Picard.height = 17;
$CheckB_Picard.location = New-Object System.Drawing.Point(202,64);

$B_Who = New-Object system.Windows.Forms.Button;
$B_Who.text = "WHO Is Your Captain?";
$B_Who.width = 330;
$B_Who.height = 55;
$B_Who.location = New-Object System.Drawing.Point(30,125);
$B_Who.Font = New-Object System.Drawing.Font('Calibri',25);
$B_Who.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$B_Who.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#bd10e0");

$TB_Output = New-Object system.Windows.Forms.TextBox;
$TB_Output.multiline = $true;
$TB_Output.width = 339;
$TB_Output.height = 216;
$TB_Output.location = New-Object System.Drawing.Point(25,190);
$TB_Output.Font = New-Object System.Drawing.Font('Comic Sans MS',16);
$TB_Output.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$TB_Output.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$GB_Top.controls.AddRange(@($CheckB_Kirk,$CheckB_Janeway,$CheckB_Picard,$CheckB_Sisko));
$Form_MAIN.controls.AddRange(@($GB_Top,$B_Who,$TB_Output));

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------

function Do_Something
{
         $TB_Output.Text = "";

         if($CheckB_Kirk.Checked)
         { $TB_Output.Text += "`r`nBest captain is " + $CheckB_Kirk.Text; }

         if($CheckB_Janeway.Checked)
         { $TB_Output.Text += "`r`nBest captain is " + $CheckB_Janeway.Text; }

         if($CheckB_Sisko.Checked)
         { $TB_Output.Text += "`r`nBest captain is " + $CheckB_Sisko.Text; }

         if($CheckB_Picard.Checked)
         { $TB_Output.Text += "`r`nBest captain is " + $CheckB_Picard.Text; }

}
#-----------------------------------------------------------------------------------------

$B_Who.Add_Click({ Do_Something; })

#-----------------------------------------------------------------------------------------

# 6. Display Form
#-----------------------------------------------------------------------------------------
$Form_Main.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################


# 1. Add the
# Powershell GUI Forms and Components - 11 Adding a ProgressBar to a Form
# Author: Carly Salali Germany
# Date: 08/04/2020
# Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize  = New-Object System.Drawing.Point(390,275);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");
$Form_MAIN.text = "Carly is Unicorn";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$L_Title = New-Object system.Windows.Forms.Label;
$L_Title.text = "Power Level";
$L_Title.AutoSize = $true;
$L_Title.width = 25;
$L_Title.height = 10;
$L_Title.location = New-Object System.Drawing.Point(145,10);
$L_Title.Font = New-Object System.Drawing.Font('Callibri',12);
$L_Title.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$L_Title.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");

$ProgressBar1 = New-Object system.Windows.Forms.ProgressBar;
$ProgressBar1.width = 329;
$ProgressBar1.height = 40;
$ProgressBar1.location = New-Object System.Drawing.Point(30,45);

$GB_Amount = New-Object system.Windows.Forms.Groupbox;
$GB_Amount.height = 117;
$GB_Amount.width = 258;
$GB_Amount.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$GB_Amount.Font = New-Object System.Drawing.Font('Courier New',10);
$GB_Amount.text = "Power Amount";
$GB_Amount.location = New-Object System.Drawing.Point(62,110);

$RB_25 = New-Object system.Windows.Forms.RadioButton;
$RB_25.text = "25% Power";
$RB_25.AutoSize = $true;
$RB_25.width = 104;
$RB_25.height = 10;
$RB_25.location = New-Object System.Drawing.Point(21,45);

$RB_50 = New-Object system.Windows.Forms.RadioButton;
$RB_50.text = "50% Power";
$RB_50.AutoSize = $true;
$RB_50.width = 104;
$RB_50.height = 10;
$RB_50.location = New-Object System.Drawing.Point(19,85);

$RB_75 = New-Object system.Windows.Forms.RadioButton;
$RB_75.text = "75% Power";
$RB_75.AutoSize = $true;
$RB_75.width = 104;
$RB_75.height = 10;
$RB_75.location = New-Object System.Drawing.Point(146,45);

$RB_100 = New-Object system.Windows.Forms.RadioButton;
$RB_100.text = "100% Power";
$RB_100.AutoSize = $true;
$RB_100.width = 104;
$RB_100.height = 10;
$RB_100.location = New-Object System.Drawing.Point(146,85);

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$GB_Amount.controls.AddRange(@($RB_25,$RB_50,$RB_75,$RB_100));
$Form_MAIN.controls.AddRange(@($L_Title,$ProgressBar1,$GB_Amount));

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------
$RB_25.Add_Click({ $ProgressBar1.Value = 25; })
$RB_50.Add_Click({ $ProgressBar1.Value = 50; })
$RB_75.Add_Click({ $ProgressBar1.Value = 75; })
$RB_100.Add_Click({ $ProgressBar1.Value = 100; })

# 6. Display Form
#-----------------------------------------------------------------------------------------
$Form_Main.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################


# Powershell GUI Forms and Components - 12 Adding a DataGridView to a Form
#Author: Carly Salali Germany
#Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize  = New-Object System.Drawing.Point(390,400);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");
$Form_MAIN.text = "Carly is Unicorn";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
$DataGridView1 = New-Object system.Windows.Forms.DataGridView;
$DataGridView1.width = 300;
$DataGridView1.height = 250;
$DataGridView1.location = New-Object System.Drawing.Point(51,116);

# Add sample columns and rows to the DataGridView for testing
$column1 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$column1.HeaderText = "Column 1"
$column2 = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$column2.HeaderText = "Column 2"
$DataGridView1.Columns.AddRange($column1, $column2)

# Add some sample rows
$DataGridView1.Rows.Add("Sample 1", "Test 1")
$DataGridView1.Rows.Add("Sample 2", "Test 2")
$DataGridView1.Rows.Add("Sample 3", "Test 3")

# 4. Add the Components to the Form
$Form_MAIN.controls.AddRange(@($DataGridView1));

# 5. Code the Event Handlers

# Event handler for DataGridView1 cell click
$DataGridView1.Add_CellClick({
    param($sender, $e)
    $clickedCellValue = $DataGridView1.Rows[$e.RowIndex].Cells[$e.ColumnIndex].Value
    [System.Windows.Forms.MessageBox]::Show("Cell clicked! Value: $clickedCellValue")
})

# Event handler for DataGridView1 cell value change
$DataGridView1.Add_CellValueChanged({
    param($sender, $e)
    $updatedValue = $DataGridView1.Rows[$e.RowIndex].Cells[$e.ColumnIndex].Value
    [System.Windows.Forms.MessageBox]::Show("Cell value changed! New value: $updatedValue")
})

# Event handler for DataGridView1 selection change
$DataGridView1.Add_SelectionChanged({
    $selectedRows = $DataGridView1.SelectedRows.Count
    [System.Windows.Forms.MessageBox]::Show("Selection changed! Selected rows: $selectedRows")
})

# 6. Display Form
$Form_MAIN.ShowDialog();

#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################


# Powershell GUI Forms and Components - 13 Adding Panels to a Form
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize  = New-Object System.Drawing.Point(390,400);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$Form_MAIN.text = "Carly is Unicorn";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$Panel1                          = New-Object system.Windows.Forms.Panel
$Panel1.height                   = 150
$Panel1.width                    = 300
$Panel1.location                 = New-Object System.Drawing.Point(42,25)

$Panel2                          = New-Object system.Windows.Forms.Panel
$Panel2.height                   = 150
$Panel2.width                    = 300
$Panel2.location                 = New-Object System.Drawing.Point(42,213)

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "checkBox"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 95
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(25,24)
$CheckBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$CheckBox2                       = New-Object system.Windows.Forms.CheckBox
$CheckBox2.text                  = "checkBox"
$CheckBox2.AutoSize              = $false
$CheckBox2.width                 = 95
$CheckBox2.height                = 20
$CheckBox2.location              = New-Object System.Drawing.Point(25,55)
$CheckBox2.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RadioButton1                    = New-Object system.Windows.Forms.RadioButton
$RadioButton1.text               = "radioButton"
$RadioButton1.AutoSize           = $true
$RadioButton1.width              = 104
$RadioButton1.height             = 20
$RadioButton1.location           = New-Object System.Drawing.Point(25,84)
$RadioButton1.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RadioButton2                    = New-Object system.Windows.Forms.RadioButton
$RadioButton2.text               = "radioButton"
$RadioButton2.AutoSize           = $true
$RadioButton2.width              = 104
$RadioButton2.height             = 20
$RadioButton2.location           = New-Object System.Drawing.Point(25,114)
$RadioButton2.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "button"
$Button1.width                   = 60
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(195,20)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $true
$TextBox1.width                  = 114
$TextBox1.height                 = 64
$TextBox1.location               = New-Object System.Drawing.Point(161,68)
$TextBox1.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "comboBox"
$ComboBox1.width                 = 241
$ComboBox1.height                = 47
$ComboBox1.location              = New-Object System.Drawing.Point(33,14)
$ComboBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline              = $true
$TextBox2.width                  = 234
$TextBox2.height                 = 63
$TextBox2.location               = New-Object System.Drawing.Point(30,66)
$TextBox2.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$Panel1.controls.AddRange(@($ComboBox1,$TextBox2));
$Panel2.controls.AddRange(@($CheckBox1,$CheckBox2,$RadioButton1,$RadioButton2,$Button1,$TextBox1));
$Form_MAIN.controls.AddRange(@($Panel1,$Panel2));

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------
# Event handler for Button1 click event
$Button1.Add_Click({
    $TextBox1.Text = "Button clicked!"
})

# Event handler for CheckBox1 checked state change
$CheckBox1.Add_CheckedChanged({
    if ($CheckBox1.Checked) {
        $TextBox2.Text = "Checkbox 1 is checked!"
    } else {
        $TextBox2.Text = "Checkbox 1 is unchecked!"
    }
})

# Event handler for RadioButton1 checked state change
$RadioButton1.Add_CheckedChanged({
    if ($RadioButton1.Checked) {
        $TextBox2.Text = "Radio button 1 is selected!"
    }
})

# Event handler for ComboBox1 selected item change
$ComboBox1.Add_SelectedIndexChanged({
    $TextBox2.Text = "Selected item: " + $ComboBox1.SelectedItem
})

#6. Display Form
#-----------------------------------------------------------------------------------------
$Form_Main.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

#########################################################################################################################


# Powershell GUI Forms and Components - 14 Adding Menus to a Form
# Author: Carly Salali Germany
# Date: 08/04/2020

# 1. Add the Required C#, .Net, Namespace and Classes 
#-----------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# 2. Instantiate a Form Object
#-----------------------------------------------------------------------------------------
$Form_MAIN = New-Object system.Windows.Forms.Form;
$Form_MAIN.ClientSize  = New-Object System.Drawing.Point(390,400);
$Form_MAIN.StartPosition = "manual";
$Form_MAIN.Location = New-Object System.Drawing.Size(600,300);
$Form_MAIN.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$Form_MAIN.text = "Carly is Unicorn";
$Form_MAIN.TopMost = $false;

# 3. Build the Form Components
#-----------------------------------------------------------------------------------------
$MainMenu = New-Object System.Windows.Forms.MenuStrip;

$Menu_File = New-Object System.Windows.Forms.ToolStripMenuItem("File");
$SubMenu_Open = New-Object System.Windows.Forms.ToolStripMenuItem("Open");
$SubMenu_Save = New-Object System.Windows.Forms.ToolStripMenuItem("Save");
$SubMenu_Exit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit");

$Menu_Options = New-Object System.Windows.Forms.ToolStripMenuItem("Options");
$Menu_View = New-Object System.Windows.Forms.ToolStripMenuItem("View");
$Menu_Help = New-Object System.Windows.Forms.ToolStripMenuItem("Help");
$Menu_About = New-Object System.Windows.Forms.ToolStripMenuItem("About");

$TB_Output = New-Object system.Windows.Forms.TextBox;
$TB_Output.multiline = $true;
$TB_Output.width = 339;
$TB_Output.height = 216;
$TB_Output.location = New-Object System.Drawing.Point(25,100);
$TB_Output.Font = New-Object System.Drawing.Font('Comic Sans MS',20);
$TB_Output.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff");
$TB_Output.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#000000");

# 4. Add the Components to the Form
#-----------------------------------------------------------------------------------------
$Menu_File.DropDownItems.Add($SubMenu_Open);
$Menu_File.DropDownItems.Add($SubMenu_Save);
$Menu_File.DropDownItems.Add($SubMenu_Exit);

$MainMenu.Items.Add($Menu_File);
$MainMenu.Items.Add($Menu_Options);
$MainMenu.Items.Add($Menu_View);
$MainMenu.Items.Add($Menu_Help);
$MainMenu.Items.Add($Menu_About);

$Form_MAIN.controls.AddRange(@($MainMenu,$TB_Output));

# 5. Code the Event Handlers
#-----------------------------------------------------------------------------------------
$SubMenu_Open.Add_Click({ $TB_Output.Text = "`r`n  Open File."; })
$SubMenu_Save.Add_Click({ $TB_Output.Text = "`r`n  Save File."; })
$SubMenu_Exit.Add_Click({ $TB_Output.Text = "`r`n  Exit Program."; })
$Menu_Options.Add_Click({ $TB_Output.Text = "`r`n  Options!"; })
$Menu_View.Add_Click({ $TB_Output.Text = "`r`n  Changing VIEW."; })
$Menu_Help.Add_Click({ $TB_Output.Text = "`r`n  Help me!"; })
$Menu_About.Add_Click({ $TB_Output.Text = "`r`n  All about ME."; })

# 6. Display Form
#-----------------------------------------------------------------------------------------
$Form_Main.ShowDialog();
#$Form_MAIN.ShowDialog() | Out-Null;

# Call the Menu again
invoke-expression -Command "$basePath\HO_ToolBox_Menu.ps1"



 








