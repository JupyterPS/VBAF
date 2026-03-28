<#                                  SOLID Principles Overview

1. Single Responsibility Principle (SRP): A class should have only one reason to change,
   meaning it should have only one job or responsibility.

2. Open/Closed Principle (OCP): Software entities should be open for extension but closed for modification.

3. Liskov Substitution Principle (LSP): Objects of a superclass should be replaceable with objects of a subclass
   without affecting the correct behavior of the program.

4. Interface Segregation Principle (ISP): No client should be forced to depend on methods it does not use.

5. Dependency Inversion Principle (DIP): High-level modules should not depend on low-level modules.
   Both should depend on abstractions.
#>

# 1. Single Responsibility Principle (SRP)

class Company4 {
    [string] $Name
    [string] $Location
    [string] $ContactNumber
    [array] $Projects
    [array] $Research
    [array] $AI

    Company4([string] $name, [string] $location, [string] $contactNumber) {
        $this.Name = $name
        $this.Location = $location
        $this.ContactNumber = $contactNumber
        $this.Projects = @()
        $this.Research = @()
        $this.AI = @()
    }

    [void] AddProject([string] $text) {
        $projectObject = [PSCustomObject]@{ Text = $text }
        $this.Projects += $projectObject
    }

    [void] ListProjects() {
        foreach ($project in $this.Projects) {
            Write-Host "$($project.Text)"
        }
    }
}
# Here, Company4 handles only the project-related functionality.
# If we have more responsibilities, we should separate them into different classes or modules.


# 2. Open/Closed Principle (OCP)
#    Make entities extendable without modifying existing code. We'll extend our StrategyBase example:

class StrategyBase {
    [void] Execute() { 
        throw "Execute method not implemented" 
    }
}

class AIResearchStrategy : StrategyBase {
    [void] Execute() {
        Write-Host "Conducting AI research..."
    }
}

class NewResearchStrategy : StrategyBase {
    [void] Execute() {
        Write-Host "Conducting New research strategy..."
    }
}

# Usage:
$strategy = [AIResearchStrategy]::new()
$strategy.Execute()

$newStrategy = [NewResearchStrategy]::new()
$newStrategy.Execute()
# Here, we can add new strategies without modifying the existing ones.


# 3. Liskov Substitution Principle (LSP)
#    Subtypes should be substitutable for their base types. Our strategy example naturally supports this:

function ExecuteStrategy([StrategyBase] $strategy) {
    $strategy.Execute()
}

# Usage:
$strategy = [AIResearchStrategy]::new()
ExecuteStrategy $strategy

$newStrategy = [NewResearchStrategy]::new()
ExecuteStrategy $newStrategy
# The ExecuteStrategy function can handle any StrategyBase type.


# 4. Interface Segregation Principle (ISP)
#    Define interfaces specific to client needs rather than one general-purpose interface.
#    PowerShell doesn't have interfaces, but we can simulate this with multiple base classes:

class IProjectManager {
    [void] AddProject([string] $text)
    [void] ListProjects()
}

(#)class Company4 : IProjectManager {
    [string] $Name
    [array] $Projects

    Company4([string] $name) {
        $this.Name = $name
        $this.Projects = @()
    }

    [void] AddProject([string] $text) {
        $projectObject = [PSCustomObject]@{ Text = $text }
        $this.Projects += $projectObject
    }

    [void] ListProjects() {
        foreach ($project in $this.Projects) {
            Write-Host "$($project.Text)"
        }
    }
}
# This helps keep the class focused on project management responsibilities.


# 5. Dependency Inversion Principle (DIP)
#    Depend on abstractions, not on concrete implementations. We'll use our strategy pattern for this:

(#)class Company4 {
    [StrategyBase] $ResearchStrategy

    Company4([StrategyBase] $researchStrategy) {
        $this.ResearchStrategy = $researchStrategy
    }

    [void] ExecuteResearch() {
        $this.ResearchStrategy.Execute()
    }
}

# Usage:
$strategy = [AIResearchStrategy]::new()
$company = [Company4]::new($strategy)
$company.ExecuteResearch()
# The Company4 class depends on the abstract StrategyBase rather than a specific implementation.






