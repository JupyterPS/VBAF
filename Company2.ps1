# Company2.ps1
Write-Host("`n")
Write-Host("                  - oo00oo -                    ")
Write-Host "=> _____ International Wine Company _______ <=`n" 

# Message box to ask the user if they want to visit the wine bar
$result = [System.Windows.Forms.MessageBox]::Show("Do you want to visit our ENOTEK winebar", 
    "Order your table from these three Yes No Cancel", "YesNoCancel")
If ($result -eq "Yes") {
    Invoke-Expression -Command "$basePath\Enotek.ps1"
}

# Define the enhanced Company2 class with combined functionalities
class Company2 : Company {
    [System.Collections.ArrayList]$Wines
    [System.Collections.Hashtable]$Inventory
    [System.Collections.Hashtable]$Prices
    [CompanyCustomerSupport]$CustomerSupport
    [System.EventHandler]$OnNewEmployeeEvent  # Event handler property

    Company2([string]$name, [string]$address, [string]$contactNumber) : base($name, $address, $contactNumber) {
        $this.Wines = [System.Collections.ArrayList]@()
        $this.Inventory = [System.Collections.Hashtable]::new()
        $this.Prices = [System.Collections.Hashtable]::new()
        $this.CustomerSupport = [CompanyCustomerSupport]::new()
        $this.OnNewEmployeeEvent = $null  # Initialize event handler to null
    }

    [void] AddWine([string]$name, [string]$area, [int]$vintageYear, [string]$classification, [decimal]$price, [int]$stock) {
        $wine = [PSCustomObject]@{
            Name = $name
            Area = $area
            VintageYear = $vintageYear
            Classification = $classification
            Price = $price
            Stock = $stock
        }
        $this.Wines.Add($wine)
        Write-Host "Wine Added: Name=$name, Area=$area, Vintage Year=$vintageYear, Classification=$classification, Price=$price, Stock=$stock"
    }

    [void] ListWines() {
        Write-Host "Wines:"
        foreach ($wine in $this.Wines) {
            Write-Host "Name: $($wine.Name), Area: $($wine.Area), Vintage Year: $($wine.VintageYear), Classification: $($wine.Classification), Price: $($wine.Price), Stock: $($wine.Stock)"
        }
    }

    [void] ReorderWine([string]$name, [int]$quantity) {
        $wine = $this.Wines | Where-Object { $_.Name -eq $name }
        if ($wine) {
            $wine.Stock += $quantity
            Write-Host "Reordered $quantity units of $name. New stock: $($wine.Stock)"
        } else {
            Write-Host "Wine $name not found."
        }
    }

    [PSCustomObject] GetWineDetails([string]$name) {
        $wine = $this.Wines | Where-Object { $_.Name -eq $name }
        return $wine
    }

    [void] UpdateStock([string]$name, [int]$newStock) {
        $wine = $this.Wines | Where-Object { $_.Name -eq $name }
        if ($wine) {
            $wine.Stock = $newStock
            Write-Host "Updated stock of $name to $newStock."
        } else { 
            Write-Host "Wine $name not found."
        }
    }

    [void] HandleCustomerInquiry([string]$customer, [string]$issue) {
        Write-Host "Inquiry from $($customer): $($issue)"
    }

    [void] OfferCustomerSupport([string]$customer, [string]$issue, [string]$resolution) {
        Write-Host "Support to $($customer): $($resolution)"
    }

    # Function to display support tickets using the CustomerSupport property
    [void] ListSupportTickets() {
        $this.CustomerSupport.ListSupportTickets()
    }

    [void] AddInventory([string]$item, [int]$quantity) {
        $this.Inventory[$item] = $quantity
        Write-Host "Inventory Added: Item=$item, Quantity=$quantity"
    }

    [void] DisplayInventory() {
        Write-Host "Inventory:"
        foreach ($item in $this.Inventory.GetEnumerator()) {
            Write-Host "Item: $($item.Name), Quantity: $($item.Value)"
        }
    }

    [void] ProcessOrder([string]$product, [int]$quantity) {
        if ($this.Inventory.ContainsKey($product)) {
            if ($this.Inventory[$product] -ge $quantity) {
                $this.Inventory[$product] -= $quantity
                Write-Host "$quantity units of $product ordered."
            } else {
                Write-Host "Not enough inventory for $product."
            }
        } else {
            Write-Host "Product $product not found in inventory."
        }
    }

    [void] UpdatePrice([string]$product, [decimal]$price) {
        $this.Prices[$product] = $price
        Write-Host "Updated price of $product to $price."
    }

    [void] DisplayPrices() {
        Write-Host "Prices:"
        foreach ($entry in $this.Prices.GetEnumerator()) {
            Write-Host "Product: $($entry.Name), Price: $($entry.Value)"
        }
    }

<# 
    [void] SpecificOperation() {
        Write-Host ">>>>>>>>>>>Performing specific operation for $($this.Name)"                Inheritance test
    }
#> 
}
                                                    
# Example usage of the enhanced Company2 class
try {

    # Load the configuration data
    $config = Import-PowerShellDataFile -Path "${basePath}\CompanyConfig.psd1"
    
    # Extract the specific company configuration
    $companyConfig = $config.Company2
    
    # Create an instance of Company2 using the configuration data
    $wineCompany = [Company2]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber)

    Write-Host "`n"
    $wineCompany.DisplayCompanyDetails()

    # Subscribe to the event
    Write-Host "`n"
    $wineCompany.OnNewEmployeeEvent = [System.EventHandler]{
        param ($sender, $e)
        Write-Host "A new employee has been added to the company."
    }

    # Add employees  
    Write-Host "`n"
    $wineCompany.AddEmployee("Emma Johnson", "Sales Manager")
    $wineCompany.AddEmployee("John Smith", "Winemaker")

    # Add customers
    Write-Host "`n"
    $wineCompany.AddCustomer("Liam Brown", "liam@example.com")
    $wineCompany.AddCustomer("Olivia Green", "olivia@example.com")

    # Add wines
    Write-Host "`n"
    $wineCompany.AddWine("Chardonnay",`
    "California", 2018, "Reserve", 29.99, 120)
    $wineCompany.AddWine("Merlot", "France",`
    2016, "Premium", 45.50, 75)
    $wineCompany.AddWine("Cabernet Sauvignon", "Australia",`
    2019, "Vintage", 60.00, 50)

    # Reorder wine stock
    Write-Host "`n"
    $wineCompany.ReorderWine("Chardonnay", 30)

    # List employees, customers, and wines
    Write-Host "`n"
    $wineCompany.ListEmployees()
    Write-Host "`n"
    $wineCompany.ListCustomers()
    Write-Host "`n"
    $wineCompany.ListWines()

    # Get details of a specific wine
    Write-Host "`n"
    $wineDetails = $wineCompany.GetWineDetails("Merlot")
    Write-Host "Details of Merlot:"
    Write-Host $wineDetails

    # Update stock of a wine
    Write-Host "`n"
    $wineCompany.UpdateStock("Chardonnay", 100)
    Write-Host "Updated stock of Chardonnay:"
    Write-Host "`n"
    $wineCompany.ListWines()

    # Add support tickets and display them
    Write-Host "`n"
    $wineCompany.CustomerSupport.AddSupportTicket("T001", "Liam Brown", "Issue with wine delivery", "Open")
    $wineCompany.CustomerSupport.AddSupportTicket("T002", "Olivia Green", "Inquiry about new wines", "Open")
    Write-Host "`n"
    $wineCompany.CustomerSupport.AssignTicketToStaff("T001", "Emma Johnson")
    Write-Host "`n"
    $wineCompany.CustomerSupport.UpdateTicketStatus("T001", "Resolved")

    # Display support tickets
    Write-Host "`n"
    $wineCompany.ListSupportTickets()

    # Additional functions from Company2.ps1      
    Write-Host "`n"                                           
    $wineCompany.AddInventory("Red Wine", 50)
    $wineCompany.AddInventory("White Wine", 70)
    Write-Host "`n"
    $wineCompany.DisplayInventory()

    Write-Host "`n"
    $wineCompany.ProcessOrder("Red Wine", 20)                                               
    $wineCompany.ProcessOrder("White Wine", 30)
    $wineCompany.ProcessOrder("Champagne", 10)        # Example of a product not in inventory

    Write-Host "`n"
    $wineCompany.HandleCustomerInquiry("David Brown", "Interested in your latest Merlot offering.")
    $wineCompany.OfferCustomerSupport("David Brown", "Inquiry about Merlot", "Could you provide more details about the Merlot?")

    Write-Host "`n"
    $wineCompany.UpdatePrice("Chardonnay", 35.99)                                            
    $wineCompany.UpdatePrice("Merlot", 50.00)
    $wineCompany.DisplayPrices()

} catch {
    Write-Host "An error occurred: $_"
}







