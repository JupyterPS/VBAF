# CompanyBase.ps1
Write-Host("`n")
Write-Host "=> _____ CompanyBase ______________________ <=`n"

# Define the base Company class
class Company {
    [string] $Name
    [string] $Location
    [string] $ContactNumber
    [System.Collections.ArrayList] $Employees = @()
    [System.Collections.ArrayList] $Customers = @()

    Company([string] $name, [string] $location, [string] $contactNumber) {
        $this.Name = $name
        $this.Location = $location
        $this.ContactNumber = $contactNumber
    }

    [void] DisplayCompanyDetails() {        
        Write-Host "Name: $($this.Name)"
        Write-Host "Location: $($this.Location)"
        Write-Host "Contact: $($this.ContactNumber)"
        Write-Host "FROM COMPANYBASE 1"
    }

    [void] AddEmployee([string] $name, [string] $position) {        
        $employee = [Employee]::new($name, $position)
        $this.Employees.Add($employee)
        Write-Host "Employee Added: Name=$name, Position=$position"
        Write-Host "FROM COMPANYBASE 2" 
    }

    [void] ListEmployees() {        
        Write-Host "Employees in $($this.Name):"
        foreach ($employee in $this.Employees) {
            Write-Host "$($employee.Name) - $($employee.Position)"
            Write-Host "FROM COMPANYBASE 3"
        }
    }

    [void] AddCustomer([string] $name, [string] $email) {        
        $customer = [Customer]::new($name, $email)
        $this.Customers.Add($customer)
        Write-Host "Customer Added: Name=$name, Email=$email"
        Write-Host "FROM COMPANYBASE 4"
    }

    [void] ListCustomers() {        
        Write-Host "Customers in $($this.Name):"
        foreach ($customer in $this.Customers) {
            Write-Host "$($customer.Name) - $($customer.Email)"
            Write-Host "FROM COMPANYBASE 5"
        }
    }

    [void] SpecificOperation() {
        Write-Host "< Performing a generic operation for $($this.Name)"
    }
}
 
# Define the Employee class
class Employee {
    [string]$Name
    [string]$Position

    Employee([string]$name, [string]$position) {
        $this.Name = $name
        $this.Position = $position
    }
}

# Define the Customer class
class Customer {
    [string]$Name
    [string]$Email

    Customer([string]$name, [string]$email) {
        $this.Name = $name
        $this.Email = $email
    }
}

# Define Company1 class inheriting from Company
class Company1 : Company {
    Company1([string] $name, [string] $location, [string] $contactNumber) : base($name, $location, $contactNumber) {}
}

# Define Company2 class inheriting from Company
class Company2 : Company {
    [hashtable] $Inventory = @{}
    [hashtable] $Prices = @{}

    Company2([string] $name, [string] $location, [string] $contactNumber) : base($name, $location, $contactNumber) {}
}

# Define Company3 class inheriting from Company
class Company3 : Company {
    [System.Collections.ArrayList] $Accounts
    [System.Collections.ArrayList] $Loans
    [string] $CEO

    Company3([string] $name, [string] $location, [string] $contactNumber, [string] $ceo) : base($name, $location, $contactNumber) {
        $this.Accounts = [System.Collections.ArrayList]::new()
        $this.Loans = [System.Collections.ArrayList]::new()
        $this.CEO = $ceo
    }
}

# Define Company4 class inheriting from Company
class Company4 : Company {
    Company4([string] $name, [string] $location, [string] $contactNumber) : base($name, $location, $contactNumber) {}
}


 






