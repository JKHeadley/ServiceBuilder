Install time: ~7m:30s

SUMMARY:

This package is meant to be used as an extension to an Entity Framework code first model.  The ServiceBuilder package will build a
service based on your model that will contain CRUD methods for all the model entities.  The service follows good design practices such
as Inversion of Control (through Castle Windsor), a generic repository to abstract database interactions, helper methods to reduce the
service size and abstract business logic, and DTOs to allow easy control over transferred data.  

REQUIREMENTS:

The main requirements for this package to install correctly is that a code first model exists and a naming convention is followed.
This convention centers around the solution name.  For a given solution name, %SOLUTION_NAME%, the project containing the model must
be named %SOLUTION_NAME%.Model, the class implementing DbContext must be named %SOLUTION_NAME%Context, and all the classes in the
project must be under the namespace %SOLUTION_NAME%.Model.

For example: 
-Solution name 				= "SuperMarket"
-Project name/namespace 	= "SuperMarket.Model"
-Context name 				= "SuperMarketContext"

Other requirements:
- The %SOLUTION_NAME%Context class implementing DbContext must be partial.
- The class implementing the user type for the system must have an attribute of [Description("User")]
- The name/username property for the user class must have an attribute of [Description("UserName")]

Ex:
----------------------------------------------------
[Description("User")]
public class MyUser
{
	public Guid Id { get; set; }
	[Description("UserName")]
	public string Name { get; set; }
}
----------------------------------------------------

INSTALLATION:

The ServiceBuilder package is installed as any other NuGet package.  If the installation runs correctly the process could take anywhere
from 7 to 8 minutes.  Once the installation is complete, click "OK" to the false error message and make sure to click "Discard" when
Visual Studio notifies you that changes have been made to the project outside the environment.  

MANUAL INSTALLATION:

If an error occurs during normal installation stating "The Service dll could not be found", then the installation process can be
completed manually with ease.  Simply navigate through the Service project and run all the T4 templates (the ".tt" files) by
right-clicking and selecting "Run Custom Tool".  If an error message occurs during any of the template generations then build the
service and try again.  Once all of the T4 templates have been run, run the command "remove_templates" in the package manager console
to remove all the generation files.