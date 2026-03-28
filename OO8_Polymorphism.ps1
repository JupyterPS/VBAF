                                                                                                                                                        <#
                                                     - oo00oo -  
                                               
                                                    Polymorphism        
                                               
                                                M A C H I N E  R O O M  
                                                
                                                (Qualified staff only) 
                                                                                                                                                               #>


# 8. Polymorphism


#########################################################################

Polymorphism commonly uses a parent class to reference a child class. In more advanced cases we rely on interfaces. 
However interfaces are not included natively in PowerShell v5.
U sing classes to demonstrate polymorphism is straightforward as seen in the next example.

#########################################################################


class Foo
{
    [string] $SomePram

    Foo([string]$somePram)
    {
        $this.SomePram = $somePram
    }

    [string] GetMessage()
    {
        return $null
    }

    [void] WriteMessage()
    {
        Write-Host($this.GetMessage())
    }
}

class Bar : Foo
{
    Bar([string]$somePram): base($somePram)
    {

    }

    [string] GetMessage()
    {
        return ("{0} Success" -f $this.SomePram)
    }
}

class Bar2 : Foo
{
    Bar2([string]$somePram): base($somePram)
    {

    }

    [string] GetMessage()
    {
        return ("{0} Success" -f $this.SomePram)
    }
}

[Foo[]] $foos = @([Bar]::new("Bar"), [Bar2]::new("Bar2"))

foreach($foo in $foos)
{
    $foo.WriteMessage()
}

Bar Success
Bar2 Success


#########################################################################
# Polymorphism commonly uses a parent class to reference a child class. 
#########################################################################

class Farver
{
    [string] $Gul

    Farver([string]$Gul)
    {
        $this.Gul = $Gul
    }

    [string] GetMessage()
    {
        return "gået i sort"  # Base class message for Sort
    }

    [void] WriteMessage()
    {
        Write-Host($this.GetMessage())
    }
}

class Blå : Farver
{
    Blå([string]$Gul): base($Gul)
    {
    }

    [string] GetMessage()
    {
        return ("{0} Himmel" -f $this.Gul)
    }
}

class Grøn : Farver
{
    Grøn([string]$Gul): base($Gul)
    {
    }

    [string] GetMessage()
    {
        return ("{0} Omstilling" -f $this.Gul)
    }
}

class Sort : Farver
{
    Sort([string]$Gul): base($Gul)
    {
    }

    # No GetMessage() method here, so it will use the base class's implementation
}

#########################################################################

# Example of usage
$blå = [Blå]::new("Blå")
$grøn = [Grøn]::new("Grøn")
$sort = [Sort]::new("Sort")

$blå.WriteMessage()   # Output: "Blå Himmel"
$grøn.WriteMessage()  # Output: "Grøn Omstilling"
$sort.WriteMessage()  # Output: "gået i sort"

#########################################################################
# To use a class, we must instantiate an object unless using static properties or methods.
#########################################################################

Write-Host("`n")
[Farver[]] $Farvers = @([Blå]::new("Blå"), [Grøn]::new("Grøn"), [Sort]::new("Sort"))

foreach($Farver in $Farvers)
{
     $Farver.WriteMessage()
}


#########################################################################
# To use a class, we must instantiate an object unless using static properties or methods.
#########################################################################

class MyClass {
    # Static property
    static [string] $StaticProperty = "I am a static property"

    # Static method
    static [string] StaticMethod() {
        return "I am a static method"
    }
}

# Accessing static property and method without instantiating the class
Write-Host [MyClass]::StaticProperty  # Output: I am a static property
Write-Host ([MyClass]::StaticMethod()) # Output: I am a static method

[MyClass]::StaticProperty  # Output: I am a static property
([MyClass]::StaticMethod()) # Output: I am a static method



