<#
Scope in PowerShell

1.    Global Scope:
        The global scope is the outermost scope. Variables and functions defined here are accessible throughout the entire PowerShell session.
        Example: Variables defined in TheCompany.ps1 before calling any other scripts are in the global scope.

2.    Script Scope:
        Each script file (.ps1) runs in its own script scope. 
        Variables and functions defined within a script are accessible only within that script unless they are explicitly exported or returned.
        Example: Variables defined within Company1.ps1 are not directly accessible in TheCompany.ps1 
        unless they are explicitly returned or made global.

3.    Local Scope:
        Local scope refers to the scope within a function or script block.
        Variables defined here are only accessible within that function or script block.
        Example: Variables defined inside a function in TheCompany.ps1 or any company-specific script are local to that function.

4.    Private Scope:
        Private scope is a child scope of the current scope. When you define a variable or function as private, 
        it is only accessible within the scope it was defined in and its child scopes.
        Example: Using private keyword in PowerShell class or function to restrict visibility.

5.    Class Scope:
        Class scope applies to variables and methods defined within a PowerShell class. 
        Class members are accessible according to their visibility (public, private, protected).

Applying Scope to Your Main Script (TheCompany.ps1)

1.    Global Scope: Any variables or functions defined at the top level of TheCompany.ps1 are in the global scope. 
        This includes the configuration loading and any functions like Initialize-Companies.
        Function Scope: Variables inside Initialize-Companies function are local to that function unless explicitly passed outside.

Company-Specific Scripts (Company1.ps1, Company2.ps1, etc.)

2.    Script Scope: Each company-specific script has its own script scope. 
        Any variables or functions defined here are local to that script unless they are part of the class definition.

Classes and Methods

5.    Class Scope: Each class (e.g., Company1, Company2) has its own scope. 
        Methods and properties of the class are accessible through instances of the class.
        Method Scope: Variables inside class methods are local to those methods.

Ensuring Proper Scope Usage

A.    Main Script to Local Script Communication:
        Import company-specific scripts using the dot-sourcing method (. "path\to\script.ps1"). 
        This ensures that any classes or functions defined in those scripts are available in the calling script's scope.

B.    Class Method Access:
        When calling a method like SpecificOperation from the main script, 
        ensure the class instance is properly created and the method is called on that instance.
        If a class does not override a method (e.g., SpecificOperation in Company2), it will use the base class's method.

C.    Event Handling and Scope:
        Event handlers, like the one defined for OnNewEmployee, have their own scope. 
        Ensure they can access necessary variables either through parameters or by being defined in a higher scope.

Summary

      Scope in PowerShell: Understanding global, script, local, private, and class scopes helps manage variables and methods effectively.
      Class Inheritance: If a derived class does not override a method, it will use the method defined in the base class.
      Dot-Sourcing: This technique ensures that functions and classes from one script are available in another.
#>