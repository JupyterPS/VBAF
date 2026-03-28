# CompanyPSSQLite.ps1

# Define paths for Win10 and Win11
$pathWin11 = "C:\Users\henni\OneDrive\SharedPowerShell\WindowsPowerShell"
$pathWin10 = "C:\Users\Henning\OneDrive\SharedPowerShell\WindowsPowerShell"

# Determine the base path dynamically
if (Test-Path $pathWin11) {
    $basePath = $pathWin11
} else {
    $basePath = $pathWin10
}

#_______________List tables (if in doubt)__________________________________________

. "${basePath}\CompanyPSSQLopen.ps1"
 
# Use of PSSqlite in upstart and in programming
$query = "SELECT name FROM sqlite_master WHERE type='table';"
$tables = Invoke-SqliteQuery -Connection $db -Query $query
$tables
#_________________________________________________________

$query = "SELECT * FROM employees"
$query = "SELECT * FROM customers"
$query = "SELECT * FROM products"
$query = "SELECT * FROM orders"
$query = "SELECT * FROM support_tickets"
$query = "SELECT * FROM Companies"

$results = Invoke-SqliteQuery -Connection $db -Query $query
# Display the results
$results | Format-Table -AutoSize

# Close the SQLite connection only if it's currently open
. "${basePath}\CompanyPSSQClose.ps1"

#_________________________________________________________

# Create a new SQLite commands and parameters               unwanted interference

$command = New-Object System.Data.SQLite.SQLiteCommand
$command.CommandText = "SELECT * FROM employees"
$command.Connection = $db

# Creates a new parameter for an SQLite command.
$parameter = New-Object System.Data.SQLite.SQLiteParameter
$parameter.ParameterName = "@name"
$parameter.Value = "John Doe"

# Add a parameter to your SQLite command
$command = New-Object System.Data.SQLite.SQLiteCommand
$parameter = New-Object System.Data.SQLite.SQLiteParameter("@name", "John Doe")
$command.Parameters.Add($parameter)

# Remove a parameter from your SQLite command
$command.Parameters.Remove($parameter)

# Converts the results of a SQL query into a .NET DataTable object.
$dataTable = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM employees" | Out-DataTable; $dataTable 

#_________________________________________________________

# Creates a new tables in the SQLite database.

Invoke-SqliteQuery -Connection $db -Query @"
CREATE TABLE IF NOT EXISTS employees (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    position TEXT NOT NULL
);
"@

# Create customers table
Invoke-SqliteQuery -Connection $db -Query @"
CREATE TABLE IF NOT EXISTS customers (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL
);
"@

# Create products table
Invoke-SqliteQuery -Connection $db -Query @"
CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    stock INTEGER NOT NULL
);
"@

# Create orders table
Invoke-SqliteQuery -Connection $db -Query @"
CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    product_id INTEGER,
    quantity INTEGER NOT NULL,
    total_price REAL NOT NULL,
    order_date TEXT NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id),
    FOREIGN KEY(product_id) REFERENCES products(id)
);
"@

# Create support_tickets table
Invoke-SqliteQuery -Connection $db -Query @"
CREATE TABLE IF NOT EXISTS support_tickets (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    issue TEXT NOT NULL,
    status TEXT NOT NULL,
    FOREIGN KEY(customer_id) REFERENCES customers(id)
);
"@

# Create Companies table
Invoke-SqliteQuery -Connection $db -Query @"
CREATE TABLE Companies (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Name TEXT NOT NULL,
    Address TEXT NOT NULL,
    ContactNumber TEXT NOT NULL,
    CEO TEXT
);
"@

# Insert data into employees table
Invoke-SqliteQuery -Connection $db -Query @"
INSERT INTO employees (name, position) VALUES ('Emma Johnson', 'Research Scientist');
INSERT INTO employees (name, position) VALUES ('John Smith', 'Production Manager');
"@

# Insert data into customers table
Invoke-SqliteQuery -Connection $db -Query @"
INSERT INTO customers (name, email) VALUES ('Liam Brown', 'liam@example.com');
INSERT INTO customers (name, email) VALUES ('Olivia Green', 'olivia@example.com');
"@

# Insert data into products table
Invoke-SqliteQuery -Connection $db -Query @"
INSERT INTO products (name, price, stock) VALUES ('Insulin', 29.99, 100);
INSERT INTO products (name, price, stock) VALUES ('Growth Hormone', 24.99, 50);
"@

# Insert data into orders table
Invoke-SqliteQuery -Connection $db -Query @"
INSERT INTO orders (customer_id, product_id, quantity, total_price, order_date) VALUES (1, 1, 9, 269.91, '2024-08-12');
INSERT INTO orders (customer_id, product_id, quantity, total_price, order_date) VALUES (2, 2, 5, 124.95, '2024-08-11');
"@

# Insert data into support_tickets table
Invoke-SqliteQuery -Connection $db -Query @"
INSERT INTO support_tickets (customer_id, issue, status) VALUES (1, 'Re: Insulin delivery', 'Open');
"@

# Insert data into Companies table
Invoke-SqliteQuery -Connection $db -Query @"
INSERT INTO Companies (Name, Address, ContactNumber, CEO) VALUES
('Novo Nordisk', 'Novo Allé, 2880 Bagsværd, Denmark', '+45 4444 8888', NULL),
('International Wine Company', '456 Vineyard Ave', '222-222-2222', NULL),
('Commerce Bank', '789 Finance Blvd', '333-333-3333', 'Keith Richard'),
('Machine Learning Support', '101 AI Dr', '444-444-4444', NULL);
"@

# Query employees table
$employees = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM employees"
$employees | Format-Table

# Query customers table
$customers = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM customers"
$customers | Format-Table

# Query products table
$products = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM products"
$products | Format-Table

# Query orders table
$orders = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM orders"
$orders | Format-Table

# Query support_tickets table
$support_tickets = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM support_tickets"
$support_tickets | Format-Table

# Query companies table
$companies = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM companies"
$companies | Format-Table

#_________________________________________________________

# Insert data into the table (like create table)

# Create a new SQLiteCommand object
$insertCmd = New-Object System.Data.SQLite.SQLiteCommand
$insertCmd.Connection = $db
$insertCmd.CommandText = "INSERT INTO employees (name, position) VALUES (@name, @position)"

# Add parameters to the command
$insertCmd.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@name", "Kenny Rodgers")))
$insertCmd.Parameters.Add((New-Object Data.SQLite.SQLiteParameter("@position", "Developer")))

# Execute the command
$insertCmd.ExecuteNonQuery()

# Query data from the table
$result = Invoke-SqliteQuery -Connection $db -Query "SELECT * FROM employees"
$result | Format-Table -AutoSize

#_________________________________________________________

# Invoke-SqliteQuery's

# Update an employee's position
Invoke-SqliteQuery -Connection $db -Query @"
UPDATE employees SET position = 'Senior Research Scientist' WHERE name = 'Emma Johnson';
"@

# Delete a customer
Invoke-SqliteQuery -Connection $db -Query @"
DELETE FROM customers WHERE name = 'Liam Brown';
"@ 

# Drops a table from the SQLite database.
Invoke-SqliteQuery -Connection $db -Query "DROP TABLE IF EXISTS employees" 
Invoke-SqliteQuery -Connection $db -Query "DROP TABLE IF EXISTS companies" 

# Retrieves the schema of the SQLite database.
$schema = Invoke-SqliteQuery -Connection $db -Query "PRAGMA table_info(employees)" 

# Updates data in an SQLite table.
Invoke-SqliteQuery -Connection $db -Query "UPDATE employees SET position = 'Manager' WHERE id = 1" 

# Inserts data into an SQLite table.
Invoke-SqliteQuery -Connection $db -Query "INSERT INTO employees (name, position) VALUES ('Jane Doe', 'Developer')"
 
# Deletes data from an SQLite table.
Invoke-SqliteQuery -Connection $db -Query "DELETE FROM employees WHERE id = 1" 
#_______
# Creates a backup of the SQLite database.
Copy-Item -Path "$basePath\Company.db" -Destination "$basePath\CompanyBackup.db" 

# Restores the SQLite database from a backup.
Copy-Item -Path "$basePath\CompanyBackup.db" -Destination "$basePath\Company.db" 
#_______
# Begins a transaction in the SQLite database.
$transaction = Invoke-SqliteQuery -Connection $db -Query "BEGIN TRANSACTION" 

# Commits the current transaction in the SQLite database.
Invoke-SqliteQuery -Connection $db -Query "COMMIT TRANSACTION" 

# Rolls back the current transaction in the SQLite database.
Invoke-SqliteQuery -Connection $db -Query "ROLLBACK TRANSACTION"

#________________________________________________________ 

# Here's 3 example scripts that demonstrates how to use PSSQLite cmdlets and methods to interact with an SQLite database: 

# 1. Executing a Non-Query Command
$insertCmd = New-Object System.Data.SQLite.SQLiteCommand
$insertCmd.CommandText = "INSERT INTO employees (name, position) VALUES (@name, @position)"
$insertCmd.Connection = $db
$insertCmd.Parameters.AddWithValue("@name", "John Doe")
$insertCmd.Parameters.AddWithValue("@position", "Developer")

# Execute the command
$insertCmd.ExecuteNonQuery()

#_________________________________________________

# 2. Executing a Query Command
$selectCmd = New-Object System.Data.SQLite.SQLiteCommand
$selectCmd.CommandText = "SELECT * FROM employees WHERE name = @name"
$selectCmd.Connection = $db

# Add a parameter to the command
$null = $selectCmd.Parameters.AddWithValue("@name", "John Doe")

# Execute the command and retrieve data
$reader = $selectCmd.ExecuteReader()
try {
    while ($reader.Read()) {
        Write-Output "Name: $($reader["name"]), Position: $($reader["position"])"
    }
}
finally {
    # Ensure the reader is closed
    $reader.Close()
}

#__________________________________________________

# 3. Executing a Scalar Command
$countCmd = New-Object System.Data.SQLite.SQLiteCommand
$countCmd.CommandText = "SELECT COUNT(*) FROM employees"
$countCmd.Connection = $db

# Execute the command and get the result
$employeeCount = $countCmd.ExecuteScalar()
Write-Output "Total number of employees: $employeeCount"

#__________________________________________________

# Define a function to check and handle the connection status
function Get-DbStatus {
    param (
        [System.Data.SQLite.SQLiteConnection]$dbConnection,
        [string]$dbName = "Database"
    )

    if ($null -eq $dbConnection) {
        Write-Output "$dbName connection object is null."
        return "Null"
    }
    
    switch ($dbConnection.State) {
        'Closed' {
            Write-Output "$dbName is closed."
            return "Closed"
        }
        'Open' {
            Write-Output "$dbName is already open."
            return "Open"
        }
        'Connecting' {
            Write-Output "$dbName is currently connecting."
            return "Connecting"
        }
        'Executing' {
            Write-Output "$dbName is executing a command."
            return "Executing"
        }
        'Fetching' {
            Write-Output "$dbName is fetching data."
            return "Fetching"
        }
        'Broken' {
            Write-Error "$dbName connection is broken."
            return "Broken"
        }
        default {
            Write-Error "Unknown state for $($dbName): $($dbConnection.State)"
            return "Unknown"
        }
    }
}

# Example of using the Get-DbStatus function
$env:PSModulePath += ";C:\Users\Henni\OneDrive\Documents\WindowsPowerShell\Modules"
Import-Module PSSQLite -Force

# Create a new connection object
$db1 = New-SqliteConnection -DataSource "$basePath\Company.db"

#$db2 = New-SqliteConnection -DataSource "C:\Path\To\Your\Database2.db"

# Check status of both databases
$statusDb1 = Get-DbStatus -dbConnection $db1 -dbName "Database1"
#$statusDb2 = Get-DbStatus -dbConnection $db2 -dbName "Database2"

# Open connections if they are closed
if ($statusDb1 -eq "Closed") {
    try {
        $db1.Open()
        Write-Output "Database1 opened successfully."
    } catch {
        Write-Error "Failed to open Database1: $_"
    }
}

if ($statusDb2 -eq "Closed") {
    try {
        $db2.Open()
        Write-Output "Database2 opened successfully."
    } catch {
        Write-Error "Failed to open Database2: $_"
    }
}

# Ensure the connections are closed when done
if ($statusDb1 -eq "Open") {
    $db1.Close()
    Write-Output "Database1 connection closed."
}

if ($statusDb2 -eq "Open") {
    $db2.Close()
    Write-Output "Database2 connection closed."
}

# List all tables in the database
$tables = Invoke-SqliteQuery -Connection $db -Query "SELECT name FROM sqlite_master WHERE type='table';"
$tables | Format-Table -AutoSize


















