<#
                                                             - oo00oo -  
                                                        
                                                           The OOP Toolbox        
                                                        
                                                         M A C H I N E  R O O M  
                                                         
                                                         (Qualified staff only) 




# Jump directly to one of the below topics. Activate (pf8) and double click on below line

. "C:\Users\henni\OneDrive\WindowsPowerShell\GREP_Jump.ps1"  
$Num = 20
Jump-To-GUISectionISE -Num $Num



                                Object-Oriented Programming (OOP) Principles with examples from real life  

 *  Classes and Objects:
        Class: A blueprint for creating objects (instances). It defines properties (attributes) and methods (behaviors).
        Object: An instance of a class that contains specific data and can perform actions defined by its class.

    Example:
        Real Life: A Car class defines properties like Color, Make, and Model, and methods like Drive() and Stop(). 
        An object could be a red Toyota Corolla.
        
 *  Inheritance:
        A mechanism where a new class (derived class) inherits properties and methods from an existing class (base class).
        Promotes code reusability and establishes a hierarchical relationship.

    Example:
        Real Life: A Vehicle base class with properties like Wheels and methods like Start(). 
        A Bicycle class inherits from Vehicle and adds a method Speed().
       
 *  Encapsulation:
        The bundling of data (attributes) and methods (functions) that operate on the data within a single unit (class). 
        It restricts direct access to some of the object's components.
        Protects the integrity of the object's data.

    Example:
        Real Life: A BankAccount class with private properties like Balance. 
        Methods like Deposit() and Withdraw() control access to the balance, preventing unauthorized changes.
       
 *  Polymorphism:
        The ability to present the same interface for different underlying data types. 
        It allows methods to do different things based on the object it is acting upon.
        Achieved through method overriding and interfaces.

    Example:
        Real Life: A Shape class with a method Draw(). Derived classes like Circle and Square implement their own versions of Draw(), 
        allowing different shapes to be drawn using the same method call.
    
 *  Composition:
        A design principle where a class is composed of one or more objects from other classes, establishing a "has-a" relationship.
        Promotes code reuse and flexibility.

    Example:
        Real Life: A Car class that contains an Engine object and a Wheel object. The Car class uses these components to function.
        
 *  Abstraction:
        The concept of hiding complex implementation details and showing only the necessary features of an object. 
        It simplifies the interface for the user.
        Achieved through abstract classes and interfaces.

    Example:
        Real Life: A RemoteControl class that provides buttons for Power, Volume, and Channel. 
        Users interact with the remote without needing to understand the internal workings of the TV.


#__________________________________________________>>> OOP Definitions summed up <<<__________________________________________________________




                                                             - oo00oo -  
                                                        
                                                          The OOP Definitions        
                                                        
                                                         M A C H I N E  R O O M  
                                                         
                                                         (Qualified staff only) 


In object-oriented programming (OOP), classes are used to define blueprints for objects. Each object created from a class
can have its own unique characteristics and behavior, even if they are of different types or characters. Here's how you can use OOP
concepts in your scenario with different firms of different characters:

Create a Base Class: Start by creating a base class that represents a generic company or firm.
This class can include common properties and methods that are shared among all types of companies.

Derive Specific Classes: Create specific classes that inherit from the base class for each type of company. Each derived class can add
its own unique properties and methods that are specific to that type of company.
For example, you might have classes like "RetailCompany", "TechCompany", "ManufacturingCompany", etc.

Override Methods: If necessary, you can override methods from the base class in the derived classes to provide custom implementations
that are specific to each type of company. This allows you to tailor the behavior of each company type as needed.

Polymorphism: Use polymorphism to treat objects of different derived classes uniformly. This means that you can use a base class reference
to refer to objects of any derived class, allowing you to write generic code that can work with different types of companies.

Encapsulation: Encapsulate the data and behavior of each company type within its respective class. This helps in organizing
and managing the complexity of your codebase by keeping related functionality together.

Composition: If there are components or subsystems shared among different types of companies, you can use composition to encapsulate
these components into separate classes and then include them as members of your company classes.

Interfaces: Define interfaces to represent common behaviors that different types of companies might exhibit. Implement these interfaces
in your company classes to ensure that they provide the required functionality.

By using OOP principles like inheritance, encapsulation, polymorphism, and composition, you can create a flexible and extensible system
for managing different types of companies with their unique characteristics and behavior.

Below, the structure of Methoods in order to substain Inheretance in Base and local Companies

CompanyBase:

    DisplayCompanyDetails
¨   AddEmployee
¨   DisplayEmployees
¨   AddCustomer
¨   ListCustomers

Company1:

    AddCustomer
    AddOrder
    AddProduct
    ListProducts
    GetProductDetails
    UpdateStock
    AddSupportStaff
    AddSupportTicket
    ListSupportTickets
    AssignTicketToStaff
    UpdateTicketStatus   

Company2:

    AddWine
    ListWines
    ReorderWine   
    GetWineDetails
    UpdateStock
    HandleCustomerInquiry
    OfferCustomerSupport
    ListSupportTickets
    AddInventory
    DisplayInventory
    ProcessOrder
    UpdatePrice
    DisplayPrices

Company3:

    UpdateCustomerEmail
    CreateSavingsAccount
    CreateCheckingAccount
    Transfer
    GetAccountDetails  
    CreateLoan
    GetLoanDetails
    DisplayAccounts
    DisplayCompanyInfo

Account:
    DisplayAccounts 
    LogTransaction
    DisplayTransactions
    Deposit
    Withdraw
SavingsAccount:
    CalculateInterest
    Deposit
    Withdraw
LoanAccount:
    CalculateMonthlyPayment
    MakePayment
    DisplayLoanDetails
Loan:
    Repay
    DisplayLoansDetails
    LogTransaction 
    DisplayTransactions    


Given that CompanyBase is the core class that controls all child companies through inheritance
and you're following the principles of inheritance, polymorphism, and encapsulation,
Any enhancement or expansion must be carefully built to align with this architecture. Each child company will need to override
or extend the methods defined in CompanyBase as needed,
While maintaining encapsulation and ensuring that polymorphism allows the correct operation to be called for each specific company.

Analysis & Key Points:

 *  Inheritance:
        The base Company class provides a template with methods like AddEmployee, ListEmployees, AddCustomer, ListCustomers,
        and SpecificOperation.
        Child classes like Company1, Company2, Company3, and Company4 can inherit and override these methods.

 *  Polymorphism:
        Methods like SpecificOperation can be overridden in each company to perform company-specific tasks
        while retaining the same method signature. This ensures that when the operation is invoked,
        the correct method for that specific company is called.

 *  Encapsulation:
        Encapsulation is achieved by restricting direct access to properties like $Employees and $Customers
        via methods like AddEmployee or AddCustomer. This keeps the underlying structure safe
        and only manipulated through predefined methods. 

#____________________________________________>>> OOP Objectives in CompanyHeadQuarters <<<________________________________________________




                                                             - oo00oo -  
                                                        
                                                          The OOP Objectives        
                                                        
                                                         M A C H I N E  R O O M  
                                                         
                                                         (Qualified staff only) 


 *  Inheritance:
Inheritance allows a class to inherit properties and methods from another class.
This is evident in my script where Company1, Company2, Company3, and Company4 inherit from the base class Company.
The CompanyBase.ps1 defines the base Company class. Other company classes (The local Companies) inherit from this base class.
This demonstrates the inheritance principle by allowing derived classes to use and override methods from the base class.
Company3 inherits from Company, gaining access to its properties and methods.

 *  Encapsulation:
Encapsulation is the concept of restricting access to certain properties and methods within an object.
This is achieved using classes and ensuring that the data is manipulated only through well-defined interfaces.
By loading these scripts, you encapsulate the related class definitions and functionalities into separate files.
Each file handles its own logic, and the main script (CompanyHeadquarters.ps1) just includes them.
The CompanyCustomerSupport class encapsulates the support ticket management functionalities within the class.
This includes adding, assigning, updating, and listing support tickets.
Instantiating an Employee object within the AddEmployee method, you keep details of employee creation encapsulated within the method.
This means that the user of the Company3 class does not need to worry about how Employee objects are created or managed;
they simply call AddEmployee with the necessary parameters.
The internal workings (creation and management of Employee and Customer objects) are encapsulated within the methods of the class.
The users of the Company3 class do not need to know the details of how Employee and Customer objects are managed;
they just use the provided methods.

 *  Polymorphism:
Polymorphism allows objects to be treated as instances of their parent class rather than their actual class.
This is evident when you override the SpecificOperation method in the Company3 class.
Despite calling SpecificOperation on an instance of Company, the overridden method in Company3 is executed.
Company3 overrides the SpecificOperation method to provide an implementation, different from the base class SpecificOperation method.
The exercise where Company3 provides its own implementation of SpecificOperation, overriding the method in the base Company class,
is an example of polymorphism
Polymorphism allows you to call the same method on different objects and have each object respond in its own way.
It is a powerful concept that enables flexible and reusable code. Your SpecificOperation method in your script is an example
of polymorphism through method overriding in inherited classes, but the concept extends to interfaces, abstract classes,
method overloading, and collections of base types, among other scenarios.

 *  Composition:
Company3 uses composition by including lists of Employees and Customers as properties in a [System.Collections.ArrayList].
This demonstrates a "has-a" relationship where Company3 has employees and customers.
By initializing ArrayList properties in the constructor and providing methods to add employees and customers,
Company3 demonstrates how composition can be effectively used to build complex types from simpler, reusable components.
Composition can be thought of as a class having built-in "managers" (methods) that handle the objects of other classes.
These "managers" are responsible for creating, storing, managing and utilizing instances of other classes
to fulfill the overall responsibilities of the class.
In composition, methods in a class act as managers that handle the creation, management, and interaction of composed objects.
This encapsulates the complexity and allows for modular, reusable, and maintainable code. It is a design principle rather
than one of the four fundamental OOP principles.
However it is very important in OOP and often discussed alongside the fundamental principles. Composition refers to designing
a class using instances of other classes, which allows you to build complex types by combining objects of other types
 
 *  Abstraction:
The user of the Company3 class only needs to know that they can add an employee by providing a name and position.
They do not need to understand the internal workings of the Employee class.
This reduces complexity and makes the Company3 class easier to use.
The concept of hiding the complex implementation details and showing only the necessary features of an object.
It helps in reducing programming complexity and effort.
#>














