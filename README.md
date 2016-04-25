# ServiceBuilder
A nuget package that builds a service around an existing Entity Framework code first model.
The nuget package can be found here: https://www.nuget.org/packages/ServiceBuilder/

See the ServiceBuilderTest project for an example project to test installation: https://github.com/JKHeadley/ServiceBuilderTest

#SUMMARY:

This package is meant to be used as an extension to an Entity Framework code first model.  The ServiceBuilder package will build a
service based on your model that will contain CRUD methods for all the model entities.  The service follows good design practices such
as Inversion of Control (through Castle Windsor), a generic repository to abstract database interactions, helper methods to reduce the
service size and abstract business logic, and DTOs to allow easy control over transferred data.  It also uses the decorator pattern to add a logging layer that automatically logs all CRUD events (including errors).

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

###NOTE: 

---
For reasons currently unkown, sometimes the nuget package installation erases the content of random model files (but not the files themselves).  Given this, a backup copy of your solution folder is created as the first step in the nuget installation process.  I've found that it is pretty easy to just open any backup files for the "erased" files and copy the contents over.  At the end of the manual installation process, the `remove_templates` command will remove this backup copy.
---

- Install the nuget package onto your model project. Make sure to click "Discard" and "Reload All" when
Visual Studio notifies you that changes have been made to the project outside the environment, and don't click "Restore" when Nuget
alerts you of missing packages.  
- Once the package installation is complete, clean the solution and build your model project (see the above note for some build errors).
- Once the model builds succesfully, step through the two new Repository and Service projects, and execute the T4 (/*.tt) template files by 
right-clicking and selecting "Run Custom Tool" (do *NOT* run any of the "MultiOutput.tt" files). The list of files needed to be run can be seen below.
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


# Inspiration:
Entity Framework provides a great standard to create code-first database models.  However once the models are created
there are a great many practices/patterns/techniqes/methods available to go about providing access to those models, 
some of which are better than others, and some of which aren't helpful at all. This can result in code that is overly complex and scales poorly.  In addition, having so many choices means its unlikely two projects will be structured similarly.  At my previous company we had multiple service projects being developed at the same time, with developers coming on and off projects and working on multiple projects simultaneously.  The lack of a standard structure resulted in high overhead for developers to get acquainted with a project.  This combined with less than efficient programming practices led to suboptimal productivity.

This service builder is not only a tool to get a fully functional CRUD service 
up and running quickly, it also implements and promotes good coding practices emphasizing modularity and separation of 
concerns.  Specifically, the following patters are represented:

- Dependency injection and Inversion of Control (IoC) via Castle Windsor: http://www.castleproject.org/projects/windsor/
- Repository pattern: https://msdn.microsoft.com/en-us/library/ff649690.aspx
- DTO pattern with built in mapping using AutoMapper: https://en.wikipedia.org/wiki/Data_transfer_object and http://automapper.org/
- Helper methods to encapsulate business logic resulting in a lightweight service class
- Decorator pattern implemented via a logging decorator that extends the repository pattern: http://www.dofactory.com/net/decorator-design-pattern

I find the decorator pattern to be particularly impressive as it allows powerful functionality to be inserted into the data access layer (DAL) without altering any classes.  It is tightly integrated with the IoC and Repository patterns and is a testament to their utility.  

The resulting structure promotes flexibility and scalability.  Custom business logic can smoothly be inserted into the helper methods.  The DTO classes allow for efficient control over remote interactions, including control over the transfer of sensitive data.  The decorator pattern allows for the DAL functionality to be easily extended.  For example, a caching decorator could be inserted alongside the logging decorator that would provide caching functionality for service transactions.  

Hopefully these tools will be of some use to the community.  Please create an issue for any questions, comments, or feature requests and I will try to respond.  And of course feel free to submit pull requests and contribute to the project.

#Contributing
Please reference the contributing doc: https://github.com/JKHeadley/ServiceBuilder/blob/master/CONTRIBUTING.md
