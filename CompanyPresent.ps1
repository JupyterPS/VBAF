# Load necessary assemblies
Add-Type -AssemblyName PresentationFramework

# Create a new window
$window = New-Object system.Windows.Window
$window.Title = "Company Presentation"
#$window.Width = 700
#$window.Height = 700

# Ensure the window is maximized
$window.WindowState = 'Maximized'

# Create a grid layout
$grid = New-Object system.Windows.Controls.Grid
$window.Content = $grid

# Add a TextBlock for the title
$title = New-Object system.Windows.Controls.TextBlock
$title.Text = "Company Headquarters"
$title.FontSize = 24
$title.HorizontalAlignment = "Center"
$title.VerticalAlignment = "Top"
$grid.Children.Add($title)

# Add a ListBox to display company details
$listBox = New-Object system.Windows.Controls.ListBox
$listBox.Margin = "10,50,10,10"
$grid.Children.Add($listBox)

# Define the presentation function
function Present-Company {
    param (
        [Company]$company
    )
    
# Function to add company details to the ListBox
function Add-CompanyDetails {
    param (
        [string]$details,
        [string]$color = "Black"  # Optional color parameter
    )
    #[void]$listBox.Items.Add($details)

    # Create a TextBlock for the item
    $textBlock = New-Object System.Windows.Controls.TextBlock
    $textBlock.Text = $details

    # Apply the color
    $textBlock.Foreground = [System.Windows.Media.Brushes]::$color

    # Add the TextBlock to the ListBox
    [void]$listBox.Items.Add($textBlock)
}

    # Display company details
    Write-Host("`n")
    Write-Host("        - oo0X0oo -                       ")   
    Write-Host "===== Company Details ====="
    $company.DisplayCompanyDetails()
    Write-Host "============================"
    Write-Host ""
    Add-CompanyDetails("                 - oo0X0oo -                       ") "Blue"
    Add-CompanyDetails "===== Company Details =====" "Black"
    Add-CompanyDetails "Name: $($companyConfig.Name)" "Green"
    Add-CompanyDetails "Location: $($companyConfig.Address)" "Green"
    Add-CompanyDetails "Contact: $($companyConfig.ContactNumber)" "Green"
    Add-CompanyDetails "============================" "Black"
    Add-CompanyDetails("`n")

    # Display employees
    Write-Host "===== Employees ====="
    Add-CompanyDetails "===== Employees ====="
    if ($company.Employees.Count -eq 0) {
        Write-Host "No employees available."
    } else {
        foreach ($employee in $company.Employees) {
            Write-Host "Name: $($employee.Name), Position: $($employee.Position)"
            Add-CompanyDetails  "Name: $($employee.Name), Position: $($employee.Position)"
        }
    }
    Write-Host "======================="
    Add-CompanyDetails "======================="
    Write-Host ""
    Add-CompanyDetails("`n")

    # Display customers
    Write-Host "===== Customers ====="
    Add-CompanyDetails "===== Customers ====="
    if ($company.Customers.Count -eq 0) {
        Write-Host "No customers available."
    } else {
        foreach ($customer in $company.Customers) {
            Write-Host "Name: $($customer.Name), Email: $($customer.Email)"
            Add-CompanyDetails "Name: $($customer.Name), Email: $($customer.Email)"
        }
    }
    Write-Host "======================="
    Add-CompanyDetails "======================="
    Write-Host ""
    Add-CompanyDetails("`n")

    # Display specific information based on company type
    switch -Wildcard ($company.GetType().Name) {
        "Company1" {
            Write-Host "===== Products ====="
            Add-CompanyDetails "===== Products ====="
            if ($company.Products.Count -eq 0) {
                Write-Host "No products available."
            } else {
                # Loop through each product in the company
                foreach ($product in $company.Products) {
                    Write-Host "Name: $($product.Name) - Price: $($product.Price) - Stock: $($product.StockLevel)"
                    Add-CompanyDetails "Name: $($product.Name) - Price: $($product.Price) - Stock: $($product.StockLevel)"
                }
            }
            Write-Host "====================="
            Add-CompanyDetails "====================="
            Write-Host ""
            Add-CompanyDetails("`n")
            Write-Host "===== Orders ====="
            Add-CompanyDetails "===== Orders ====="
            if ($company.AllOrders.Count -eq 0) {
                Write-Host "No orders available."
            } else {                        
                # Loop through each order in the company
                foreach ($order in $company.AllOrders) {
                    Write-Host "Product: $($order.ProductName), Quantity: $($order.Quantity), Total Price: $($order.TotalPrice), Date: $($order.OrderDate)"
                    Add-CompanyDetails "Product: $($order.ProductName), Quantity: $($order.Quantity), Total Price: $($order.TotalPrice), Date: $($order.OrderDate)"
                } 
            }
            Write-Host "====================="
            Add-CompanyDetails "====================="
            Write-Host ""
            Add-CompanyDetails("`n")
            Write-Host "===== Support Tickets ====="
            Add-CompanyDetails "===== Support Tickets ====="
            if ($company.SupportTickets.Count -eq 0) {
                Write-Host "No support tickets available."
            } else {
                    foreach ($ticket in $company.SupportTickets) {
                    Write-Host "Ticket ID: $($ticket.ID), Customer: $($ticket.Customer), Issue: $($ticket.Issue), Status: $($ticket.Status)"
                    Add-CompanyDetails "Ticket ID: $($ticket.ID), Customer: $($ticket.Customer), Issue: $($ticket.Issue), Status: $($ticket.Status)"
                } 
            }
            Write-Host "==========================="
            Add-CompanyDetails "==========================="
            Write-Host ""
            Add-CompanyDetails("`n")
            Write-Host "===== Support Staff ====="
            Add-CompanyDetails "===== Support Staff ====="
            if ($company.SupportStaff.Count -eq 0) {
                Write-Host "No support staff available."
            } else {
                foreach ($staff in $company.SupportStaff) {
                    Write-Host "Name: $($staff.Name), Level: $($staff.Level)"
                    Add-CompanyDetails "Name: $($staff.Name), Level: $($staff.Level)"
                }
            }
            Write-Host "========================="
            Add-CompanyDetails "========================="
            Write-Host ""
            Add-CompanyDetails("`n")
        }
        "Company2" {
            Write-Host "===== Inventory ====="
            Add-CompanyDetails "===== Inventory ====="
            if ($company.Inventory.Count -eq 0) {
                Write-Host "No inventory available."
            } else {
                foreach ($item in $company.Inventory.GetEnumerator()) {
                    Write-Host "Item: $($item.Key), Quantity: $($item.Value)"
                    Add-CompanyDetails "Item: $($item.Key), Quantity: $($item.Value)"
                }
            }
            Write-Host "====================="
            Add-CompanyDetails "====================="
            Write-Host ""
            Add-CompanyDetails("`n")

            Write-Host "===== Prices ====="
            Add-CompanyDetails "===== Prices ====="
            if ($company.Prices.Count -eq 0) {
                Write-Host "No prices available."
            } else {
                foreach ($price in $company.Prices.GetEnumerator()) {
                    Write-Host "Item: $($price.Key), Price: $($price.Value)"
                    Add-CompanyDetails "Item: $($price.Key), Price: $($price.Value)"
                }
            }
            Write-Host "====================="
            Add-CompanyDetails "====================="
            Write-Host ""
            Add-CompanyDetails("`n")
        }
        "Company3" {
            Write-Host "===== Accounts ====="
            Add-CompanyDetails "===== Accounts ====="
            if ($company.Accounts.Count -eq 0) {
                Write-Host "No accounts available."
            } else {
                foreach ($account in $company.Accounts) {
                    Write-Host "Account ID: $($account.ID), Balance: $($account.Balance)"
                    Add-CompanyDetails "Account ID: $($account.ID), Balance: $($account.Balance)"
                }
            }
            Write-Host "====================="
            Add-CompanyDetails "====================="
            Write-Host ""
            Add-CompanyDetails("`n")

            Write-Host "===== Accounts ====="
            Add-CompanyDetails "===== Accounts ====="
            if ($company.Loans.Count -eq 0) {
                Write-Host "No loans available."
            } else {
                foreach ($loan in $company.Loans) {
                    Write-Host "Loan ID: $($loan.ID), Amount: $($loan.Amount), Status: $($loan.Status)"
                    Add-CompanyDetails "Loan ID: $($loan.ID), Amount: $($loan.Amount), Status: $($loan.Status)"
                }
            }
            Write-Host "====================="
            Add-CompanyDetails "====================="
            Write-Host ""
            Add-CompanyDetails("`n")
        }
        "Company4" {
            Write-Host "===== Projects ====="
            Add-CompanyDetails "===== Projects ====="
            if ($company.Projects.Count -eq 0) {
                Write-Host "No projects available."
            } else {
                foreach ($project in $company.Projects) {
                    Write-Host "Project Name: $($project.Text)"
                    Add-CompanyDetails "Project Name: $($project.Text)"
                }
            }
            Write-Host "====================="
            Add-CompanyDetails "====================="
            Write-Host ""
            Add-CompanyDetails("`n")

            Write-Host "===== Research Papers ====="
            Add-CompanyDetails "===== Research Papers ====="
            if ($company.Research.Count -eq 0) {
                Write-Host "No Research papers available."
            } else {
                foreach ($researches in $company.Research) {
                    Write-Host "Title: $($researches.Text)"
                    Add-CompanyDetails "Title: $($researches.Text)"
                }
            }
            Write-Host "==========================="
            Add-CompanyDetails "==========================="
            Write-Host ""
            Add-CompanyDetails("`n")

            Write-Host "===== AI research ====="
            Add-CompanyDetails "===== AI research ====="
            if ($company.AI.Count -eq 0) {
                Write-Host "No AI Research available."
            } else {
                foreach ($AI in $company.AI) {
                    Write-Host "Title: $($AI.Text)"
                    Add-CompanyDetails "Title: $($AI.Text)"
                }
            }
            Write-Host "==========================="
            Add-CompanyDetails "==========================="
            Write-Host ""
        }
    }
}
CLS
# Example usage with Company1 instance
# Load the configuration data
$config = Import-PowerShellDataFile -Path "${basePath}\CompanyConfig.psd1" 
CLS
Write-Host("       - oo0x0oo -                       ")
Write-Host "===== Company1 Usage ====="
Write-Host("`n")
# Extract and use Company1 configuration
$companyConfig = $config.Company1
$novoNordisk = [Company1]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber)
$novoNordisk.AddEmployee("Emma Johnson", "Research Scientist")  
$novoNordisk.AddEmployee("John Smith", "Production Manager")  
$novoNordisk.AddCustomer("Liam Brown", "liam@example.com")  
$novoNordisk.AddCustomer("Olivia Green", "olivia@example.com")  
$novoNordisk.AddProduct("Insulin", 29.99)
$novoNordisk.AddProduct("Growth Hormone", 24.99)
$novoNordisk.ListProducts()
$novoNordisk.UpdateStock("Insulin", 100)
$order1 = [Order]::new("Insulin", 9, 299.96, (Get-Date))
$order2 = [Order]::new("Hormone", 5, 124.95, (Get-Date).AddDays(-1))
$order3 = [Order]::new("Insulin", 2, 159.98, (Get-Date).AddDays(-2))
$novoNordisk.AddOrder("Liam Brown", $order1)
$novoNordisk.AddOrder("Liam Brown", $order2)
$novoNordisk.AddOrder("Olivia Green", $order3)
$novoNordisk.ListOrders()
$novoNordisk.AddSupportTicket("T001", "Liam Brown", "Re: Insulin delivery", "Open")
$novoNordisk.ListSupportTicket
$novoNordisk.AddSupportStaff("Support Staff 1", "Level 1")
$novoNordisk.ListSupportStaff
Write-Host "============================"
Write-Host("`n")
Present-Company -company $novoNordisk
Write-Host("`n")

Write-Host("       - oo0x0oo -                       ")
Write-Host "===== Company2 Usage ====="
# Example usage with Company2 instance
# Extract and use Company2 configuration
$companyConfig = $config.Company2
$wineCompany = [Company2]::new($companyConfig.Name, $companyConfig.Location, $companyConfig.ContactNumber)
$wineCompany.AddEmployee("Alice Brown", "Sommelier")  
$wineCompany.AddEmployee("Bob White", "Vineyard Manager")  
$wineCompany.AddCustomer("Charlie Black", "charlie@example.com")  
$wineCompany.AddCustomer("Diana Blue", "diana@example.com")  
$wineCompany.Inventory.Add("Red Wine", 150)
$wineCompany.Inventory.Add("White Wine", 200)
$wineCompany.Prices.Add("Red Wine", 19.99)
$wineCompany.Prices.Add("White Wine", 17.99)
Write-Host "============================"
Write-Host("`n")
Present-Company -company $wineCompany
Write-Host("`n")

Write-Host("       - oo0x0oo -                       ")
Write-Host "===== Company3 Usage ====="
# Example usage with Company3 instance
# Extract and use Company3 configuration
$companyConfig = $config.Company3
$commerceBank = [Company3]::new($companyConfig.Name, $companyConfig.Location, $companyConfig.ContactNumber, $companyConfig.CEO)
[void]$commerceBank.AddEmployee("David Green", "Account Manager")  
[void]$commerceBank.AddEmployee("Eva White", "Loan Officer")  
[void]$commerceBank.AddCustomer("Frank Black", "frank@example.com")  
[void]$commerceBank.AddCustomer("Grace Blue", "grace@example.com")  
[void]$commerceBank.Accounts.Add([PSCustomObject]@{ ID = "A001"; Balance = 10000 })
[void]$commerceBank.Accounts.Add([PSCustomObject]@{ ID = "A002"; Balance = 15000 })
[void]$commerceBank.Loans.Add([PSCustomObject]@{ ID = "L001"; Amount = 5000; Status = "Approved" })
[void]$commerceBank.Loans.Add([PSCustomObject]@{ ID = "L002"; Amount = 7000; Status = "Pending" })
Write-Host "============================"
Write-Host("`n")
Present-Company -company $commerceBank
Write-Host("`n")

Write-Host("       - oo0x0oo -                       ")
Write-Host "===== Company4 Usage ====="
# Example usage with Company4 instance
# Extract and use Company4 configuration
$companyConfig = $config.Company4
$machineLearning = [Company4]::new("Machine Learning Support, Analytics, and Innovation", "123 Innovation Blvd", "555-5678",$researchStrategy, $developmentStrategy, $collaborationStrategy, $evaluationStrategy)
$machineLearning.AddEmployee("Alice Blue", "Marketing Manager")  
$machineLearning.AddEmployee("Bob Red", "Sales Manager")  
$machineLearning.AddCustomer("Charlie Yellow", "charlie@example.com")  
$machineLearning.AddCustomer("Diana Pink", "diana@example.com")
$machineLearning.AddProject("Implementing Sales Forecasting")
$machineLearning.AddProject("Implementing Recommendation Systems")
$machineLearning.AddProject("Automating Customer Support")
$machineLearning.AddProject("Generating Product Recommendations")
$machineLearning.AddProject("Implementing Fraud Detection")
$machineLearning.AddResearch("Analyzing Customer Data for Insights")
$machineLearning.AddAI("Examplemodel")
$machineLearning.AddAI("Modeltraining")
$machineLearning.AddAI("TrainPredictionmodel")
$machineLearning.AddAI("TrainSalesForecastModel")
$machineLearning.AddAI("AIChatbot")
Write-Host "Listing Projects"
$machineLearning.ListProjects()
Write-Host "============================"
Write-Host("`n")
Present-Company -company $machineLearning
CLS
# Show the window
$window.ShowDialog()







