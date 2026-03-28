# Company3.ps1
Write-Host("`n")
Write-Host("                  - oo00oo -                     ")
Write-Host "=> _____ International Commerce Bank ______ <=`n"

# Define Account class
class Account {
    [guid] $AccountNumber
    [string] $Customer
    [string] $AccountType
    [double] $Balance
    [System.Collections.ArrayList] $Transactions

    Account([guid] $accountNumber, [string] $customer, [string] $accountType, [double] $balance) {
        $this.AccountNumber = $accountNumber
        $this.Customer = $customer
        $this.AccountType = $accountType
        $this.Balance = $balance
        $this.Transactions = [System.Collections.ArrayList]::new()
    }

    [void] DisplayAccounts() {
        Write-Host "Accounts in $($this.Name):"
        foreach ($account in $this.Accounts) {
            Write-Host "AccountNumber: $($account.AccountNumber)"
            Write-Host "Customer: $($account.Customer)"
            Write-Host "AccountType: $($account.AccountType)"
            Write-Host "Balance: $($account.Balance)"
            Write-Host "Transactions: $($account.Transactions)"
        }
    }

    [void] LogTransaction([string] $type, [double] $amount) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $transaction = "{0} - {1}: {2:C}" -f $timestamp, $type, $amount
        $this.Transactions.Add($transaction)
    }

    [void] DisplayTransactions() {
        Write-Host "Transactions for Account $($this.AccountNumber):"
        foreach ($transaction in $this.Transactions) {
            Write-Host $transaction
        }
    }

    [void] Deposit([double] $amount) {
        $this.Balance += $amount
        $this.LogTransaction("Deposit", $amount)
    }

    [void] Withdraw([double] $amount) {
        if ($amount -le $this.Balance) {
            $this.Balance -= $amount
            $this.LogTransaction("Withdraw", $amount)
        } else {
            Write-Host "Insufficient funds"
        }
    }
}

# Define SavingsAccount class inheriting from Account
class SavingsAccount : Account {
    [double] $InterestRate

    SavingsAccount([guid] $accountNumber, [string] $customer, [double] $balance, [double] $interestRate) : base($accountNumber, $customer, "Savings", $balance) {
        $this.InterestRate = $interestRate
    }

    [void] CalculateInterest() {
        $interest = $this.Balance * ($this.InterestRate / 100)
        $this.Balance += $interest
        $this.LogTransaction("Interest", $interest)
        Write-Host "Interest of $interest added to account $($this.AccountNumber). New Balance: $($this.Balance)"
    }

    [void] Deposit([double] $amount) {
        $this.Balance += $amount
        $this.LogTransaction("Deposit", $amount)
    }

    [void] Withdraw([double] $amount) {
        if ($amount -le $this.Balance) {
            $this.Balance -= $amount
            $this.LogTransaction("Withdraw", $amount)
        } else {
            Write-Host "Insufficient funds"
        }
    }
}

# Define LoanAccount class inheriting from Account
class LoanAccount : Account {
    [double] $InterestRate
    [double] $LoanAmount
    [double] $MonthlyPayment

    LoanAccount([guid] $accountNumber, [string] $customer, [double] $balance, [double] $loanAmount, [double] $interestRate) : base($accountNumber, $customer, "Loan", $balance) {
        $this.InterestRate = $interestRate
        $this.LoanAmount = $loanAmount
        $this.MonthlyPayment = $this.CalculateMonthlyPayment()
    }

    [double] CalculateMonthlyPayment() {
        $rate = $this.InterestRate / 1200
        $n = 12 * 30  # Assuming a 30-year loan
        $this.MonthlyPayment = $this.LoanAmount * $rate / (1 - [math]::Pow((1 + $rate), -$n))
        return [math]::Round($this.MonthlyPayment, 2)
    }

    [void] MakePayment([double] $amount) {
        if ($amount -le $this.Balance) {
            $this.Balance -= $amount
            $this.LogTransaction("Loan Payment", $amount)
        } else {
            Write-Host "Insufficient funds to make payment"
        }
    }

    [void] DisplayLoanDetails() {
        Write-Host "Loan Details:"
        Write-Host "LoanID: $($this.LoanID)"
        Write-Host "Customer: $($this.Customer)"
        Write-Host "Amount: $($this.Amount)"
        Write-Host "InterestRate: $($this.InterestRate)%"
        Write-Host "TermMonths: $($this.TermMonths)"
        Write-Host "Balance: $($this.Balance)"
    }
}

# Define CheckingAccount class inheriting from Account
class CheckingAccount : Account { 
    CheckingAccount([guid] $accountNumber, [string] $customer, [double] $balance) : base($accountNumber, $customer, "Checking", $balance) {}
}

# Define Loan class
class Loan {
    [guid]   $LoanID
    [string] $Customer
    [double] $Amount
    [double] $InterestRate
    [int]    $TermMonths
    [double] $Balance
    [System.Collections.ArrayList] $Transactions

    Loan([guid] $loanID, [string] $customer, [double] $amount, [double] $interestRate, [int] $termMonths) {
        $this.LoanID = $loanID
        $this.Customer = $customer
        $this.Amount = $amount
        $this.InterestRate = $interestRate
        $this.TermMonths = $termMonths
        $this.Balance = $amount  # Initialize balance with the amount
        $this.Transactions = [System.Collections.ArrayList]::new()
    }

    [void] Repay([double] $amount) {
        if ($this.Balance -ge $amount) {
            $this.Balance -= $amount
            $this.LogTransaction("Repayment", $amount)
            Write-Host "Repaid $amount. New Balance: $($this.Balance)"
        } else {
            Write-Host "Insufficient funds for repayment"
        }
    }

    [void] DisplayLoanDetails() {
        Write-Host "Loan Details:"
        Write-Host "LoanID: $($this.LoanID)"
        Write-Host "Customer: $($this.Customer)"
        Write-Host "Amount: $($this.Amount)"
        Write-Host "InterestRate: $($this.InterestRate)%"
        Write-Host "TermMonths: $($this.TermMonths)"
        Write-Host "Balance: $($this.Balance)"
    }

    [void] LogTransaction([string] $type, [double] $amount) {
        $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $transaction = "{0} - {1}: {2:C}" -f $timestamp, $type, $amount
        $this.Transactions.Add($transaction)
    }    
    
    [void] DisplayTransactions() {
        Write-Host "Transactions for Loan $($this.LoanID):"
        foreach ($transaction in $this.Transactions) {
            Write-Host $transaction
        }
    }
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

    [void] UpdateCustomerEmail([string] $name, [string] $newEmail) {
        $customer = $this.Customers | Where-Object { $_.Name -eq $name }
        if ($customer) {
            $customer.UpdateEmail($newEmail)
        } else {
            Write-Host "Customer not found"
        }
    }

    [guid] CreateSavingsAccount([string] $customer, [double] $initialDeposit, [double] $interestRate) {
        $accountNumber = [guid]::NewGuid()
        $account = [SavingsAccount]::new($accountNumber, $customer, $initialDeposit, $interestRate)
        $this.Accounts.Add($account)
        Write-Host "Savings Account Created: Customer=$customer, Initial Deposit=$initialDeposit, Interest Rate=$interestRate%"
        return $accountNumber
    }

    [guid] CreateCheckingAccount([string] $customer, [double] $initialDeposit) {
        $accountNumber = [guid]::NewGuid()
        $account = [CheckingAccount]::new($accountNumber, $customer, $initialDeposit)
        $this.Accounts.Add($account)
        Write-Host "Checking Account Created: Customer=$customer, Initial Deposit=$initialDeposit"
        return $accountNumber
    }

    [void] AddAccount([Account] $account) {
        $this.Accounts.Add($account)
    }

    [void] Deposit([guid] $accountNumber, [double] $amount) {
        $account = $this.Accounts | Where-Object { $_.AccountNumber -eq $accountNumber }
        if ($account) {
            $account.Balance += $amount
            $account.LogTransaction("Deposit", $amount)
            Write-Host "Deposited $amount into Account $accountNumber. New Balance: $($account.Balance)"
        } else {
            throw "Account not found"
        }
    }

    [void] Withdraw([guid] $accountNumber, [double] $amount) {
        $account = $this.Accounts | Where-Object { $_.AccountNumber -eq $accountNumber }
        if ($account) {
            if ($account.Balance -ge $amount) {
                $account.Balance -= $amount
                $account.LogTransaction("Withdraw", $amount)
                Write-Host "Withdrawn $amount from Account $accountNumber. New Balance: $($account.Balance)"
            } else {
                throw "Insufficient funds"
            }
        } else {
            throw "Account not found"
        }
    }

    [void] Transfer([guid] $fromAccountNumber, [guid] $toAccountNumber, [double] $amount) {
        $fromAccount = $this.Accounts | Where-Object { $_.AccountNumber -eq $fromAccountNumber }
        $toAccount = $this.Accounts | Where-Object { $_.AccountNumber -eq $toAccountNumber }
        if ($fromAccount -and $toAccount) {
            if ($fromAccount.Balance -ge $amount) {
                $fromAccount.Balance -= $amount
                $toAccount.Balance += $amount
                $fromAccount.LogTransaction("Transfer Out", $amount)
                $toAccount.LogTransaction("Transfer In", $amount)
                Write-Host "Transferred $amount from Account $fromAccountNumber to Account $toAccountNumber. New Balances: From= $($fromAccount.Balance), To= $($toAccount.Balance)"
            } else {
                throw "Insufficient funds in the source account"
            }
        } else {
            throw "One or both accounts not found"
        }
    }

    [PSCustomObject] GetAccountDetails([guid] $accountNumber) {
        $account = $this.Accounts | Where-Object { $_.AccountNumber -eq $accountNumber }
        if ($account) {
            return $account
        } else {
            return [PSCustomObject]@{ Error = "Account not found" }
        }
    }

    [guid] CreateLoan([string] $customer, [double] $amount, [double] $interestRate, [int] $termMonths) {
        $loanID = [guid]::NewGuid()
        $loan = [Loan]::new($loanID, $customer, $amount, $interestRate, $termMonths)
        $this.Loans.Add($loan)
        Write-Host "Loan Created: Customer=$customer, Amount=$amount, Interest Rate=$interestRate%, Term=$termMonths months"
        return $loanID
    }

    [void] RepayLoan([guid] $loanID, [double] $amount) {
        $loan = $this.Loans | Where-Object { $_.LoanID -eq $loanID }
        if ($loan) {
            $loan.Repay($amount)
            Write-Host "Repaid $amount towards Loan $loanID. Remaining Balance: $($loan.Balance)"
        } else {
            $loanAccount = $this.Accounts | Where-Object { $_.AccountNumber -eq $loanID }
            if ($loanAccount) {
                $loanAccount.MakePayment($amount)
                Write-Host "Repaid $amount towards Loan Account $loanID. Remaining Balance: $($loanAccount.Balance)"
            } else {
                Write-Host "Loan not found"
            }
        }
    }

    [PSCustomObject] GetLoanDetails([guid] $loanID) {
        $loan = $this.Loans | Where-Object { $_.LoanID -eq $loanID }
        if ($loan) {
            return $loan
        } else {
            return [PSCustomObject]@{ Error = "Loan not found" }
        }
    }

    [void] DisplayAccounts() {
        Write-Host "Accounts in $($this.Name):"
        foreach ($account in $this.Accounts) {
            Write-Host "AccountNumber: $($account.AccountNumber)"
            Write-Host "Customer: $($account.Customer)"
            Write-Host "AccountType: $($account.AccountType)"
            Write-Host "Balance: $($account.Balance)"
            $account.DisplayTransactions()
        }
    }

    [void] DisplayLoans() {
        Write-Host "Loans in $($this.Name):"
        foreach ($loan in $this.Loans) {
            Write-Host "LoanID: $($loan.LoanID)"
            Write-Host "Customer: $($loan.Customer)"
            Write-Host "Amount: $($loan.Amount)"
            Write-Host "InterestRate: $($loan.InterestRate)"
            Write-Host "TermMonths: $($loan.TermMonths)"
            Write-Host "Balance: $($loan.Balance)"
            $loan.DisplayTransactions()
        }
    }

    [void] DisplayCompanyInfo() {
        Write-Host "Company: $($this.Name)"
        Write-Host "Number of Accounts: $($this.Accounts.Count)"
        foreach ($account in $this.Accounts) {
            Write-Host "AccountNumber: $($account.AccountNumber)"
            Write-Host "Customer: $($account.Customer)"
            Write-Host "AccountType: $($account.AccountType)"
            Write-Host "Balance: $($account.Balance)"
        }
    }

    [void] SpecificOperation() {
        Write-Host ">>Performing specific operation for $($this.Name)"
    }
}

# Corrected Example usage of Company3 functionalities

# Load the configuration data
$config = Import-PowerShellDataFile -Path "${basePath}\CompanyConfig.psd1"
# Extract the specific company configuration
$companyConfig = $config.Company3

# Create an instance of Company3 using the configuration data
$commerceBank = [Company3]::new($companyConfig.Name, $companyConfig.Address, $companyConfig.ContactNumber, $companyConfig.CEO)

# Display company details
$commerceBank.DisplayCompanyDetails()

# Add employees
Write-Host("`n")
$commerceBank.AddEmployee("Alice", "Manager")
$commerceBank.AddEmployee("Bob", "Accountant")

# Add customers
Write-Host("`n")
$commerceBank.AddCustomer("John Smith", "john.smith@example.com")
$commerceBank.AddCustomer("Jane Doe", "jane.doe@example.com")

# Create accounts
Write-Host("`n")
$savingsAccountNumber = $commerceBank.CreateSavingsAccount("John Smith", 1000, 1.5)
$checkingAccountNumber = $commerceBank.CreateCheckingAccount("Jane Doe", 500)

# Create a new account
$savingsAccount = [SavingsAccount]::new([guid]::NewGuid(), "Jane Doe", 1000, 1.5)
Write-Host "SavingsAccount created: $($savingsAccount.AccountNumber) - Customer: $($savingsAccount.Customer) - Balance: $($savingsAccount.Balance) - Interest Rate: $($savingsAccount.InterestRate)%"

# Create a new account
$account = [Account]::new([guid]::NewGuid(), "John Doe", "Checking", 1000.00)

# Create loans
Write-Host("`n")
$loanID = $commerceBank.CreateLoan("John Smith", 5000, 3.5, 12)

# Perform transactions
Write-Host("`n")
$commerceBank.Deposit($savingsAccountNumber, 500)
$commerceBank.Withdraw($checkingAccountNumber, 200)
$commerceBank.Transfer($savingsAccountNumber, $checkingAccountNumber, 300)

# Display account details
Write-Host("`n")
$commerceBank.GetAccountDetails($savingsAccountNumber)
$commerceBank.GetAccountDetails($checkingAccountNumber)

# Display loan details
Write-Host("`n")
Write-Output "Loan Details:"
$commerceBank.GetLoanDetails($loanID)

# Display all loans
Write-Host("`n")
Write-Output "All Loans:"
$commerceBank.DisplayLoans()

# Display all accounts
Write-Host("`n")
Write-Output "All Accounts:"
$commerceBank.DisplayAccounts()

# Log some transactions
$account.LogTransaction("Deposit", 500.00)
$account.LogTransaction("Withdrawal", 200.00)

# Display the transactions
Write-Host("`n")
$account.DisplayTransactions()

# Deposit money
$account.Deposit(500.0)
Write-Host "Balance after deposit: $($account.Balance)"

# Withdraw money
$account.Withdraw(200.0)
Write-Host "Balance after withdrawal: $($account.Balance)"

# Calculate interest
$savingsAccount.CalculateInterest()
Write-Host "Balance after interest calculation: $($savingsAccount.Balance)"

$savingsAccount.Withdraw(200.0)
Write-Host "Balance after deposit: $($savingsAccount.Balance)"

$savingsAccount.Deposit(500.0)
Write-Host "Balance after deposit: $($savingsAccount.Balance)"

# Create loans
Write-Host("`n")
$loanID = $commerceBank.CreateLoan("John Smith", 5000, 3.5, 12)

# Example usage for LoanAccount
$loanAccount = [LoanAccount]::new([guid]::NewGuid(), "Jane Smith", 50000.0, 100000.0, 5.0)
$commerceBank.AddAccount($loanAccount)
Write-Host "Loan Account created: $($loanAccount.AccountNumber) - Customer: $($loanAccount.Customer) - Loan Amount: $($loanAccount.LoanAmount) - Interest Rate: $($loanAccount.InterestRate)% - Monthly Payment: $($loanAccount.MonthlyPayment)"

# Repay loan
$commerceBank.RepayLoan($loanID, 1000)

# Make a payment
$loanAccount.MakePayment(1500.0)
Write-Host "Balance after loan payment: $($loanAccount.Balance)"

# Make a payment on the loan
$commerceBank.RepayLoan($loanAccount.AccountNumber, 1500.0)

# Calculate monthly payment
$monthlyPayment = $loanAccount.CalculateMonthlyPayment()
Write-Host "Monthly Payment for loan: $monthlyPayment"

# Display loan details
$loanAccount.DisplayLoanDetails()

# Display company info
$commerceBank.DisplayCompanyInfo()
 
 

 












