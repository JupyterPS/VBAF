# Company1.ps1
Write-Host("`n")
Write-Host("                - oo00oo -                      ")
Write-Host "=> ___________ Novo Nordisk _______________ <=`n"

function Write-CompanyMessage {
    param(
        [string]$message
    )
    Write-Host $message
}

try {
    Write-CompanyMessage " $_"

    # Define Order class
    class Order {
        [string] $ProductName
        [int] $Quantity
        [double] $TotalPrice
        [datetime] $OrderDate
    
        Order([string] $productName, [int] $quantity, [double] $totalPrice, [datetime] $orderDate) {
            $this.ProductName = $productName
            $this.Quantity = $quantity
            $this.TotalPrice = $totalPrice
            $this.OrderDate = $orderDate
        }
    }
    
    # Define Customer class
    class Customer {
        [string] $Name
        [string] $Email
        [System.Collections.ArrayList] $Orders
    
        Customer([string] $name, [string] $email) {
            $this.Name = $name
            $this.Email = $email
            $this.Orders = [System.Collections.ArrayList]@()
        } 
    }

    # Define Company1 class inheriting from CompanyBase
    class Company1 : Company {
        [System.Collections.ArrayList] $Products
        [System.Collections.ArrayList] $SupportTickets
        [System.Collections.ArrayList] $SupportStaff
        [System.Collections.ArrayList] $AllOrders
      
        # Constructor
        Company1([string] $name, [string] $location, [string] $contactNumber) : base($name, $location, $contactNumber) {
            $this.Products = [System.Collections.ArrayList]@()
            $this.SupportTickets = [System.Collections.ArrayList]@()
            $this.SupportStaff = [System.Collections.ArrayList]@() 
            $this.AllOrders = [System.Collections.ArrayList]@()          
        }  
        
        # Add a customer
        [void] AddCustomer([string] $name, [string] $email) {
            $customer = [Customer]::new($name, $email)
            $this.Customers.Add($customer)
            Write-Host "Customer Added: Name=$name, Email=$email"
        }  
        
        # Add an order to a customer and to the company's order list
        [void] AddOrder([string] $customerName, [Order] $order) {
            $customer = $this.Customers | Where-Object { $_.Name -eq $customerName }
            if ($customer) {
                $customer.Orders.Add($order)
                $this.AllOrders.Add($order)
                Write-Host "Order Added for Customer: $customerName, Product=$($order.ProductName), Quantity=$($order.Quantity), TotalPrice=$($order.TotalPrice)"
            } else {
                Write-Host "Customer $customerName not found."
            }
        }
        
        # List all orders
        [void] ListOrders() {
            if ($this.AllOrders.Count -eq 0) {
                Write-Host "No orders available."
            } else {
                foreach ($order in $this.AllOrders) {
                    Write-Host "Product: $($order.ProductName), Quantity: $($order.Quantity), Total Price: $($order.TotalPrice), Date: $($order.OrderDate)"
                }
            }
        }         

        # Add a product
        [void] AddProduct([string] $name, [double] $price) {
            $product = [PSCustomObject]@{
                Name = $name
                Price = $price
                StockLevel = 0  # Initialize stock level to zero
            }
            $this.Products.Add($product)
            Write-CompanyMessage "Product Added: Name=$name, Price=$price"
        }

        # List all products
        [void] ListProducts() {
            foreach ($product in $this.Products) {
                Write-CompanyMessage "$($product.Name) - $($product.Price) - Stock: $($product.StockLevel)"
            }
        }

        # Get details of a specific product
        [PSCustomObject] GetProductDetails([string] $productName) {
            $product = $this.Products | Where-Object { $_.Name -eq $productName }
            if ($product) {
                return $product
            } else {
                Write-CompanyMessage "Product '$productName' not found."
                return $null
            }
        }
        
        # Update stock level of a product
        [void] UpdateStock([string] $productName, [int] $newStockLevel) {
            $product = $this.Products | Where-Object { $_.Name -eq $productName }
            if ($product) {
                $product.StockLevel = $newStockLevel
                Write-CompanyMessage "Stock level for '$productName' updated to $newStockLevel"
            } else {
                Write-CompanyMessage "Product '$productName' not found."
            }
        }
        
        # Add support staff
        [void] AddSupportStaff([string] $name, [string] $level) {
            $staff = [PSCustomObject]@{
                Name = $name
                Level = $level
            }
            $this.SupportStaff.Add($staff)
            Write-CompanyMessage "Support Staff Added: Name=$name, Level=$level"
        }

        # Add a support ticket
        [void] AddSupportTicket([string] $id, [string] $customer, [string] $issue, [string] $status) {
            $ticket = [PSCustomObject]@{
                ID = $id
                Customer = $customer
                Issue = $issue
                Status = $status
                AssignedStaff = $null
            }
            $this.SupportTickets.Add($ticket)
            Write-CompanyMessage "Support Ticket Added: ID=$id, Customer=$customer, Issue=$issue, Status=$status"
        }

        # List all support tickets
        [void] ListSupportTickets() {
            foreach ($ticket in $this.SupportTickets) {
                Write-CompanyMessage "Ticket ID: $($ticket.ID), Customer: $($ticket.Customer), Issue: $($ticket.Issue), Status: $($ticket.Status)"
                if ($ticket.AssignedStaff) {
                    Write-CompanyMessage "Assigned to: $($ticket.AssignedStaff.Name)"
                }
            }
        }

        # Assign a ticket to a staff member
        [void] AssignTicketToStaff([string] $id, [PSCustomObject] $staff) {
            $ticket = $this.SupportTickets | Where-Object { $_.ID -eq $id }
            if ($ticket) {
                $ticket.AssignedStaff = $staff
                Write-CompanyMessage "Ticket ID $id assigned to staff: $($staff.Name)"
            } else {
                Write-CompanyMessage "Ticket with ID $id not found."
            }
        }

        # Update the status of a ticket
        [void] UpdateTicketStatus([string] $id, [string] $status) {
            $ticket = $this.SupportTickets | Where-Object { $_.ID -eq $id }
            if ($ticket) {
                $ticket.Status = $status
                Write-CompanyMessage "Ticket ID $id status updated to $status"
            } else {
                Write-CompanyMessage "Ticket with ID $id not found."
            }
        } 

        [void] SpecificOperation() {
            Write-CompanyMessage ">>Performing specific operation for $($this.Name)"
        }         
    }

    function Generate-SalesReport {
    param (
        [Company]$company
    )

    $report = @()
    foreach ($customer in $company.Customers) {
        foreach ($order in $customer.Orders) {
            $report += [PSCustomObject]@{
                CustomerName = $customer.Name
                ProductName  = $order.ProductName
                Quantity     = $order.Quantity
                TotalPrice   = $order.TotalPrice
                OrderDate    = $order.OrderDate
            }
        }
    }
    return $report
    }

    # Load the configuration data
    $config = Import-PowerShellDataFile -Path "${basePath}\CompanyConfig.psd1"
      
    # Extract the specific company configuration
    $companyConfig = $config.Company1
    
    # Create an instance of Company1 using the configuration data
    #$novoNordisk = [Company1]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber)

    # Example of fetching data from the database
    $companyData = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM Companies WHERE Name = 'Novo Nordisk'"
    $novoNordisk = [Company1]::new($companyData.Name, $companyData.Address, $companyData.ContactNumber)

    # Display company details
    Write-CompanyMessage "`n"
    $novoNordisk.DisplayCompanyDetails()

    # Add employees 
    Write-CompanyMessage "`nEmployees:"
    $novoNordisk.AddEmployee("Emma Johnson", "Research Scientist")            
    $novoNordisk.AddEmployee("John Smith", "Production Manager")                                                                                 
    $novoNordisk.ListEmployees()   
    
    # Add customers   
    Write-CompanyMessage "`nCustomers:"
    $novoNordisk.AddCustomer("Liam Brown", "liam@example.com")
    $novoNordisk.AddCustomer("Olivia Green", "olivia@example.com")   
    $novoNordisk.ListCustomers()

    # Add products
    Write-CompanyMessage "`nProducts:"
    $novoNordisk.AddProduct("Insulin", 29.99)
    $novoNordisk.AddProduct("Growth Hormone", 24.99)   
    $novoNordisk.ListProducts()

    # Get details of a specific product
    $productDetails = $novoNordisk.GetProductDetails("Insulin")
    Write-CompanyMessage "`nDetails of Insulin:"
    Write-CompanyMessage $productDetails

    # Update stock for a product
    $novoNordisk.UpdateStock("Insulin", 100)   

    # Adding support staff
    Write-CompanyMessage "`n"
    $novoNordisk.AddSupportStaff("Support Staff 1", "Level 1")
    $novoNordisk.AddSupportStaff("Support Staff 2", "Level 2")
    $novoNordisk.AddSupportStaff("Support Staff 3", "Level 3")

    # Adding more support staff
    $novoNordisk.AddSupportStaff("Support Staff 4", "Level 3")
    $novoNordisk.AddSupportStaff("Support Staff 5", "Level 1")
    
    # List all support staff
    Write-Host "`nSupport Staff:"
    $novoNordisk.SupportStaff

    # Add support tickets
    Write-CompanyMessage "`n"
    $novoNordisk.AddSupportTicket("T001", "Liam Brown", "Issue with Insulin delivery", "Open")
    $novoNordisk.AddSupportTicket("T002", "Olivia Green", "Technical support needed for Growth Hormone", "Open")
    $novoNordisk.AddSupportTicket("T003", "Liam Brown", "Billing inquiry", "Open")

    # Update ticket status
    Write-CompanyMessage "`n"
    $novoNordisk.UpdateTicketStatus("T001", "In Progress")
    $novoNordisk.UpdateTicketStatus("T002", "In Progress")

    # Assign ticket to staff
    Write-CompanyMessage "`n"
    $staffMember = $novoNordisk.SupportStaff | Where-Object { $_.Level -eq "Level 1" }
    $novoNordisk.AssignTicketToStaff("T001", $staffMember)

    # List support tickets
    Write-CompanyMessage "`nSupport Tickets:"
    $novoNordisk.ListSupportTickets()

    # Add orders
    $order1 = [Order]::new("Insulin", 10, 299.9, (Get-Date))
    $order2 = [Order]::new("Growth Hormone", 5, 124.95, (Get-Date).AddDays(-1))
    $order3 = [Order]::new("Insulin", 2, 59.98, (Get-Date).AddDays(-2))
    
    $novoNordisk.AddOrder("Liam Brown", $order1)
    $novoNordisk.AddOrder("Liam Brown", $order2)
    $novoNordisk.AddOrder("Olivia Green", $order3)
    $novoNordisk.ListOrders()
    
    # Generate and display the sales report
    $salesReport = Generate-SalesReport -company $novoNordisk
    $salesReport | Out-Host  
 
} catch {
    Write-CompanyMessage "Error: $_"
}






