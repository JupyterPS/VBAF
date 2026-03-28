Add-Type -AssemblyName PresentationFramework

# Create the Window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Enterprise Simulator HQ" Height="600" Width="900" Background="#222">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="*"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Pharma -->
        <Border Grid.Row="0" Grid.Column="0" Background="#3366CC" CornerRadius="12" Padding="10" Margin="5">
            <StackPanel>
                <TextBlock Text="Pharma Company" FontSize="20" Foreground="White"/>
                <TextBlock Text="Employees: 120" Foreground="White"/>
                <TextBlock Text="Projects: 15" Foreground="White"/>
            </StackPanel>
        </Border>

        <!-- Wine -->
        <Border Grid.Row="0" Grid.Column="1" Background="#800020" CornerRadius="12" Padding="10" Margin="5">
            <StackPanel>
                <TextBlock Text="Wine Company" FontSize="20" Foreground="White"/>
                <TextBlock Text="Bottles Sold: 5,200" Foreground="White"/>
                <TextBlock Text="Customers: 340" Foreground="White"/>
            </StackPanel>
        </Border>

        <!-- Bank -->
        <Border Grid.Row="1" Grid.Column="0" Background="#001F54" CornerRadius="12" Padding="10" Margin="5">
            <StackPanel>
                <TextBlock Text="Bank" FontSize="20" Foreground="White"/>
                <TextBlock Text="Accounts: 1,230" Foreground="White"/>
                <TextBlock Text="Loans Approved: 89" Foreground="White"/>
            </StackPanel>
        </Border>

        <!-- Machine Learning -->
        <Border Grid.Row="1" Grid.Column="1" Background="#228B22" CornerRadius="12" Padding="10" Margin="5">
            <StackPanel>
                <TextBlock Text="ML Company" FontSize="20" Foreground="White"/>
                <TextBlock Text="Chatbot Sessions: 540" Foreground="White"/>
                <TextBlock Text="Accuracy: 92%" Foreground="White"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
"@

# Load XAML
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Window=[Windows.Markup.XamlReader]::Load($reader)

# Show the Window
$Window.ShowDialog() | Out-Null
