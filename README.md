# ServiceBuilder
A nuget package that builds a service around an existing Entity Framework code first model.

See the ServiceBuilderTest project for an example project to test installation: https://github.com/JKHeadley/ServiceBuilderTest

#SUMMARY:

This package is meant to be used as an extension to an Entity Framework code first model.  The ServiceBuilder package will build a
service based on your model that will contain CRUD methods for all the model entities.  The service follows good design practices such
as Inversion of Control (through Castle Windsor), a generic repository to abstract database interactions, helper methods to reduce the
service size and abstract business logic, and DTOs to allow easy control over transferred data.  It also uses the decorator pattern to added a logging layer that automatically logs all CRUD events.

#REQUIREMENTS:

The main requirements for this package to install correctly is that a code first model exists and a naming convention is followed.
This convention centers around the solution name.  For a given solution name, %SOLUTION\_NAME%, the project containing the model must
be named %SOLUTION\_NAME%.Model, the class implementing DbContext must be named %SOLUTION\_NAME%Context, and all the classes in the
project must be under the namespace %SOLUTION\_NAME%.Model.

For example: 
- Solution name 			= "SuperMarket"
- Project name/namespace 	= "SuperMarket.Model"
- Context name 				= "SuperMarketContext"

##Other requirements:
- The %SOLUTION\_NAME%Context class implementing DbContext must be partial.
- The class implementing the user type for the system must have an attribute of [Description("User")]
- The name/username property for the user class must have an attribute of [Description("UserName")]

Ex:
```C#
[Description("User")]
public class MyUser
{
	public Guid Id { get; set; }
	[Description("UserName")]
	public string Name { get; set; }
}
```

#INSTALLATION:


Currently installation is a semi-manual process.  A fully automated installation is in the works but the process is 
complex and buggy.  The installation steps are as follows:

- Install the nuget package onto your model project. Make sure to click "Discard" and "Reload All" when
Visual Studio notifies you that changes have been made to the project outside the environment.  
- Once the package installation is complete, clean the solution and build your model project.
- Once the model builds succesfully, step through the two new Repository and Service projects, and execute the T4 (/*.tt) template files by 
right-clicking and selecting "Run Custom Tool" (excluding any "MultiOutput.tt" files). The list of files needed to be run can be seen below.
If at any point a file cannot be run (specifically once you reach "GenerateHelpersInstaller.tt"), build the solution and continue.
- Once all of the T4 templates have been executed, build the solution again.
- If the solution builds succesfully, run the command `remove_templates` in the Package Manager Console.  This should remove all the T4 templates
along with any other extra files and the result should be clean service and repository projects.
- Finally, run the command `insert_log_table` in the Package Manager Console to add a migration for the LogEvent model and update your database.
- Installation is complete, you now have a fully functional CRUD service for your model.
   

##T4 Templates to Execute
- LoggingConfiguration.tt
- GenerateDTOs.tt
- GenerateHelpers.tt
- GenerateHelpersInstaller.tt
- GenerateServiceInstaller.tt
- GenerateDTOMapper.tt
- GenerateIDTOMapper.tt
- GenerateIService.tt
- GenerateService.tt
