param($installPath, $toolsPath, $package, $project)

Write-Host "Installing...";

$solutionPath = Split-Path -Path $dte.Solution.FullName -Parent

$solutionName = [io.path]::GetFileNameWithoutExtension($dte.Solution.FullName)
$Exclusive = $false;

$modelPath = "$solutionPath\$solutionName" + ".Model";

$repoPath = "$solutionPath\$solutionName" + ".Repository";

$servicePath = "$solutionPath\$solutionName" + ".Service";

$from = $installPath
$to = $installPath + "_copy"
Copy-Item $from $to -recurse
$installPath = $to

[System.Windows.Forms.MessageBox]::Show("Replacing stand in names with correct names.")
Write-Host "Replacing stand in names with correct names..."

#replace stand in names with correct names
$files = Get-ChildItem -Path "$installPath\ServiceBuilder.Repository" -Recurse

foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { 
    $_ -replace "%SERVICEBUILDER%", $solutionName `
    } |  Set-Content $file.PSPath | Out-Null
}

$files = Get-ChildItem -Path "$installPath\ServiceBuilder.Service" -Recurse

#WARNING: model dll path could vary on project, should find a more robust way to locate it's path
foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { 
    $_ -replace "%MODELDLL%", "$modelPath\bin\Debug\$solutionName.Model.dll" `
    
    } |  Set-Content $file.PSPath | Out-Null
}
foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { 
    $_ -replace "%SERVICEDLL%", "$servicePath\bin\$solutionName.Service.dll" `
    
    } |  Set-Content $file.PSPath | Out-Null
}
foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { 
    $_ -replace "%SERVICEBUILDER%", $solutionName `
    
    } |  Set-Content $file.PSPath | Out-Null
}

#Replace the "ServiceBuilder" strings with the correct solution name
$newName = "I" + $solutionName + "Repository.cs";
rename-item -path "$installPath\ServiceBuilder.Repository\IServiceBuilderRepository.cs" -newname $newName;
$newName = $solutionName + "Repository.cs";
rename-item -path "$installPath\ServiceBuilder.Repository\ServiceBuilderRepository.cs" -newname $newName;

#--------------------------------------------------------------------------------------------------------------#
#------------------------------------------Create the repository project---------------------------------------#
#--------------------------------------------------------------------------------------------------------------#

$repoProjectName = $solutionName + ".Repository.csproj";

md -Path $repoPath

[System.Windows.Forms.MessageBox]::Show("Creating Repository project.")
Write-Host "Creating Repository project..."


#add the repository project
$dte.Solution.AddFromTemplate($installPath + "\ServiceBuilder.Repository\ServiceBuilder.Repository.csproj", $repoPath, $repoProjectName, $Exclusive)


#--------------------------------------------------------------------------------------------------------------#
#------------------------------------------Create the service project------------------------------------------#
#--------------------------------------------------------------------------------------------------------------#

$serviceProjectName = $solutionName + ".Service.csproj";

md -Path $servicePath

[System.Windows.Forms.MessageBox]::Show("Creating Service project.")
Write-Host "Creating Service project..."


#add the service project
$dte.Solution.AddFromTemplate($installPath + "\ServiceBuilder.Service\ServiceBuilder.Service.csproj", $servicePath, $serviceProjectName, $Exclusive)

[System.Windows.Forms.MessageBox]::Show("Building the solution.")
Write-Host "Building the solution..."

#build solution to save changes and install missing nuget packages
$dte.Solution.SolutionBuild.Build($true)

#--------------------------------------------------------------------------------------------------------------#
#------------------------------------------Fix model reference in service project------------------------------#
#--------------------------------------------------------------------------------------------------------------#

#get the line in the solution containing the model project guid
$line = select-string -path "$solutionPath/$solutionName.sln" -pattern "$solutionName.Model" -SimpleMatch

#search the line for guids
$ex=new-object System.Text.RegularExpressions.Regex("\{[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\}",[System.Text.RegularExpressions.RegexOptions]::Singleline)
$guids=$ex.Matches($line)

#the model guid is the last guid in the line
$modelGuid =  $guids.item($guids.count-1).value

#access the service csproj file to fix the model reference guid
$serviceProject = Get-Project "$solutionName.Service"
[xml]$proj = Get-Content $serviceProject.FullName

foreach ($item in $proj.Project.ItemGroup) 
{  
    foreach ($child in $item.ChildNodes) 
    { 
        if ($child.Name -eq "$solutionName.Model") 
        {  
            [System.Windows.Forms.MessageBox]::Show("Fixing model guid reference");
            Write-Host "Fixing model guid reference..."
            $child.Project = $modelGuid; 
        }  
    } 
}
$proj.Save($serviceProject.FullName);




#--------------------------------------------------------------------------------------------------------------#
#--------------------Set auto_install to true for complete installation (has been buggy)-----------------------#
#--------------------------------------------------------------------------------------------------------------#
$auto_install = false;


if ($auto_install)
{ 

    #--------------------------------------------------------------------------------------------------------------#
    #--------------------Generate helper classes from T4 templates and add them to the project---------------------#
    #--------------------------------------------------------------------------------------------------------------#


    #[System.Windows.Forms.MessageBox]::Show("Generating Helpers.")
    Write-Host "Generating Helpers..."

    #run the T4 template "GenerateHelpers.tt"
    & "$toolsPath/AIT.Tools.VisualStudioTextTransform/AIT.Tools.VisualStudioTextTransform.exe" $dte.Solution.FullName --TargetDir "$servicePath\Helpers" --TargetFile "GenerateHelpers.tt" 2>&1 | Add-Content log.txt

    #add helpers to the service project
    foreach ($item in $proj.Project.ItemGroup)
    {  
        if ($item.ChildNodes.item(0).Name -eq "Compile")
        {
            $group = $item;
        }
    }

    $files = Get-ChildItem -Path "$servicePath\Helpers"

    #[System.Windows.Forms.MessageBox]::Show("Adding helpers to the service csproj.")
    Write-Host "Adding helpers to the service csproj..."

    foreach ($file in $files)
    {
        $fileName = $file.Name
        if ($fileName -Match "\.cs")
        {
            #add helpers to csproj
            $child = $proj.CreateElement("Compile");
            $child.SetAttribute("Include","Helpers\$fileName");
            $group.AppendChild($child);
        }
    }

    #this gets added in during "CreateElement" and must be removed manually
    $proj = [xml] $proj.OuterXml.Replace(" xmlns=`"`"", "")

    $proj.Save($serviceProject.FullName);


    #compiling apparently erases changes made to csproj
    #$dte.Solution.SolutionBuild.BuildProject("Debug", $serviceProject.FullName, $true)
    #$dte.Solution.SolutionBuild.Build($true)


    #copy over whole solution just so we can build and get the service dll

    #[System.Windows.Forms.MessageBox]::Show("Helpers added. Creating copy solution.")
    Write-Host "Helpers added. Creating copy solution..."

    $from = $solutionPath
    $to = $solutionPath + "_copy"
    Copy-Item $from $to -recurse


    $solutionPath_copy = $to

    #[System.Windows.Forms.MessageBox]::Show("Opening copy solution and building.")
    Write-Host "Opening copy solution and building..."

    $dte.Solution.Open("$solutionPath_copy\$solutionName.sln")


    $copyProj = Get-Project "$solutionName.Service"

    $dte.Solution.SolutionBuild.Build($true) 2>&1 | Add-Content log.txt


    $copyServiceBinPath = "$solutionPath_copy\$solutionName.Service\bin\$solutionName.Service.dll"
    $serviceBinPath = "$servicePath\bin\$solutionName.Service.dll"

    #[System.Windows.Forms.MessageBox]::Show("Build Finished, copying bin folder to original service.")
    Write-Host "Build Finished, copying bin folder to original service..."

    Copy-Item  -Path $copyServiceBinPath -Destination "$servicePath\bin"


    if (-Not (Test-Path "$servicePath\bin\$solutionName.Service.dll"))
    {
        [System.Windows.Forms.MessageBox]::Show("Error: Service Dll not found.")
        $dte.Solution.Open("$solutionPath\$solutionName.sln")
        throw "Service Dll not found."
    }


    #[System.Windows.Forms.MessageBox]::Show("Re-opening original solution, then generating DTOs.")
    Write-Host "Re-opening original solution, then generating DTOs..."

    $dte.Solution.Open("$solutionPath\$solutionName.sln")

    #--------------------------------------------------------------------------------------------------------------#
    #------------------------------Create DTOs and Mapper and add them to the project------------------------------#
    #--------------------------------------------------------------------------------------------------------------#

    #run the T4 template "GenerateDTOs.tt"
    & "$toolsPath/AIT.Tools.VisualStudioTextTransform/AIT.Tools.VisualStudioTextTransform.exe" $dte.Solution.FullName --TargetDir "$servicePath\DTOs" --TargetFile "GenerateDTOs.tt" 2>&1 | Add-Content log.txt


    $serviceProject = Get-Project "$solutionName.Service"
    [xml]$proj = Get-Content $serviceProject.FullName
    #add DTOs to the service project
    foreach ($item in $proj.Project.ItemGroup)
    {  
        if ($item.ChildNodes.item(0).Name -eq "Compile")
        {
            $group = $item;
        }
    }

    $files = Get-ChildItem -Path "$servicePath\DTOs"

    #[System.Windows.Forms.MessageBox]::Show("Adding DTOs to the service csproj.")
    Write-Host "Adding DTOs to the service csproj..."

    foreach ($file in $files)
    {
        $fileName = $file.Name
        if ($fileName -Match "\.cs")
        {
            #add helpers to csproj
            $child = $proj.CreateElement("Compile");
            $child.SetAttribute("Include","DTOs\$fileName");
            $group.AppendChild($child);
        }
    }

    #this gets added in during "CreateElement" and must be removed manually
    $proj = [xml] $proj.OuterXml.Replace(" xmlns=`"`"", "")

    $proj.Save($serviceProject.FullName);

    #[System.Windows.Forms.MessageBox]::Show("DTOs generated, now generating Mapper...")
    Write-Host "DTOs generated, now generating DTO mapper..."


    #run the T4 template "GenerateDTOMapper.tt"
    & "$toolsPath/AIT.Tools.VisualStudioTextTransform/AIT.Tools.VisualStudioTextTransform.exe" $dte.Solution.FullName --TargetDir "$servicePath\Mapper" --TargetFile "GenerateDTOMapper.tt" 2>&1 | Add-Content log.txt


    #[System.Windows.Forms.MessageBox]::Show("Mapper generated, now generating Mapper interface...")
    Write-Host "DTO mapper generated, now generating DTO mapper interface..."

    #run the T4 template "GenerateIDTOMapper.tt"
    & "$toolsPath/AIT.Tools.VisualStudioTextTransform/AIT.Tools.VisualStudioTextTransform.exe" $dte.Solution.FullName --TargetDir "$servicePath\Mapper" --TargetFile "GenerateIDTOMapper.tt" 2>&1 | Add-Content log.txt


    #[System.Windows.Forms.MessageBox]::Show("Mapper interface generated, now generating service...")
    Write-Host "DTO mapper interface generated, now generating service methods..."

    #add Mapper to the service project
    foreach ($item in $proj.Project.ItemGroup)
    {  
        if ($item.ChildNodes.item(0).Name -eq "Compile")
        {
            $group = $item;
        }
    }

    $files = Get-ChildItem -Path "$servicePath\Mapper"

    #[System.Windows.Forms.MessageBox]::Show("Adding Mapper to the service csproj.")
    Write-Host "Adding Mapper to the service csproj..."

    foreach ($file in $files)
    {
        $fileName = $file.Name
        if ($fileName -Match "\.cs")
        {
            #add helpers to csproj
            $child = $proj.CreateElement("Compile");
            $child.SetAttribute("Include","Mapper\$fileName");
            $group.AppendChild($child);
        }
    }

    #this gets added in during "CreateElement" and must be removed manually
    $proj = [xml] $proj.OuterXml.Replace(" xmlns=`"`"", "")

    $proj.Save($serviceProject.FullName);





    #--------------------------------------------------------------------------------------------------------------#
    #-------------------------Fill out service with previously generated helper functions--------------------------#
    #--------------------------------------------------------------------------------------------------------------#

    #run the T4 template "GenerateService.tt"
    & "$toolsPath/AIT.Tools.VisualStudioTextTransform/AIT.Tools.VisualStudioTextTransform.exe" $dte.Solution.FullName --TargetDir "$servicePath" --TargetFile "GenerateService.tt" 2>&1 | Add-Content log.txt


    #[System.Windows.Forms.MessageBox]::Show("Service methods generated, now generating service interface..")
    Write-Host "Service methods generated, now generating service interface..."


    #run the T4 template "GenerateIService.tt"
    & "$toolsPath/AIT.Tools.VisualStudioTextTransform/AIT.Tools.VisualStudioTextTransform.exe" $dte.Solution.FullName --TargetDir "$servicePath" --TargetFile "GenerateIService.tt" 2>&1 | Add-Content log.txt


    #[System.Windows.Forms.MessageBox]::Show("IService generated, generating HelpersInstaller.cs")
    Write-Host "IService generated, now generating HelpersInstaller.cs..."

    #--------------------------------------------------------------------------------------------------------------#
    #-------------------------------Generate HelpersInstaller and add it to the project----------------------------#
    #--------------------------------------------------------------------------------------------------------------#

    #run the T4 template "GenerateHelpersInstaller.tt"
    & "$toolsPath/AIT.Tools.VisualStudioTextTransform/AIT.Tools.VisualStudioTextTransform.exe" $dte.Solution.FullName --TargetDir "$servicePath\Installers" --TargetFile "GenerateHelpersInstaller.tt" 2>&1 | Add-Content log.txt


    #add HelperInstaller.cs to the service project
    $serviceProject = Get-Project "$solutionName.Service"
    [xml]$proj = Get-Content $serviceProject.FullName

    foreach ($item in $proj.Project.ItemGroup)
    {  
        if ($item.ChildNodes.item(0).Name -eq "Compile")
        {
            $group = $item;
        }
    }

    $files = Get-ChildItem -Path "$servicePath\Installers"

    #[System.Windows.Forms.MessageBox]::Show("Adding HelpersInstaller.cs to the service csproj.")
    Write-Host "Adding HelpersInstaller.cs to the service csproj..."

    foreach ($file in $files)
    {
        $fileName = $file.Name
        if ($fileName -Match "HelpersInstaller.cs")
        {
            #add HelpersInstaller.cs to csproj
            $child = $proj.CreateElement("Compile");
            $child.SetAttribute("Include","Installers\$fileName");
            $group.AppendChild($child);
        }
    }

    #this gets added in during "CreateElement" and must be removed manually
    $proj = [xml] $proj.OuterXml.Replace(" xmlns=`"`"", "")

    $proj.Save($serviceProject.FullName);

    #--------------------------------------------------------------------------------------------------------------#
    #-------------------------------Generate ServiceInstaller and add it to the project----------------------------#
    #--------------------------------------------------------------------------------------------------------------#

    #run the T4 template "GenerateServiceInstaller.tt"
    & "$toolsPath/AIT.Tools.VisualStudioTextTransform/AIT.Tools.VisualStudioTextTransform.exe" $dte.Solution.FullName --TargetDir "$servicePath\Installers" --TargetFile "GenerateServiceInstaller.tt" 2>&1 | Add-Content log.txt


    #add ServiceInstaller.cs to the service project
    $serviceProject = Get-Project "$solutionName.Service"
    [xml]$proj = Get-Content $serviceProject.FullName

    foreach ($item in $proj.Project.ItemGroup)
    {  
        if ($item.ChildNodes.item(0).Name -eq "Compile")
        {
            $group = $item;
        }
    }

    $files = Get-ChildItem -Path "$servicePath\Installers"

    #[System.Windows.Forms.MessageBox]::Show("Adding ServiceInstaller.cs to the service csproj.")
    Write-Host "Adding ServiceInstaller.cs to the service csproj..."

    foreach ($file in $files)
    {
        $fileName = $file.Name
        if ($fileName -Match "ServiceInstaller.cs")
        {
            #add HelpersInstaller.cs to csproj
            $child = $proj.CreateElement("Compile");
            $child.SetAttribute("Include","Installers\$fileName");
            $group.AppendChild($child);
        }
    }

    #this gets added in during "CreateElement" and must be removed manually
    $proj = [xml] $proj.OuterXml.Replace(" xmlns=`"`"", "")

    $proj.Save($serviceProject.FullName);



    #--------------------------------------------------------------------------------------------------------------#
    #------------------------------------------Delete temporary files----------------------------------------------#
    #--------------------------------------------------------------------------------------------------------------#

    #[System.Windows.Forms.MessageBox]::Show("HelperInstaller generated, removing T4 templates from project.")
    Write-Host "HelperInstaller generated, removing T4 templates from project..."

    #loop through and remove all references to .tt or .txt files from the csproj

    $serviceProject = Get-Project "$solutionName.Service"
    [xml]$proj = Get-Content $serviceProject.FullName
    $done = "false"
    while ($done -eq "false")
    {
        $done = "true"
        foreach ($item in $proj.Project.ItemGroup)
        {  
            if ($item.ChildNodes.item(0).Name -eq "Content")
            {
                $group = $item;
                foreach ($child in $group.ChildNodes)
                {     
                    if ($child.Attributes.item(0).Value -Match "\.tt" -or $child.Attributes.item(0).Value -Match "\.txt")
                    {
                        $done = "false"
                        $group.RemoveChild($child)
                    }
                }
            }
        }

        foreach ($item in $proj.Project.ItemGroup)
        {  
            if ($item.ChildNodes.item(0).Name -eq "Compile")
            {
                $group = $item;
                foreach ($child in $group.ChildNodes)
                {     
                    if ($child.Attributes.item(0).Value -Match "\.tt" -or $child.Attributes.item(0).Value -Match "\.txt")
                    {
                        $done = "false"
                        $group.RemoveChild($child) 
                    }
                }
            }
        }
    }


    $proj.Save($serviceProject.FullName);

    #[System.Windows.Forms.MessageBox]::Show("Deleting temporary files.")
    Write-Host "Deleting temporary files..."

    $files = Get-ChildItem -Path "$servicePath" -Recurse
    foreach ($file in $files)
    {
        $fileName = $file.Name
        if ($fileName -Match "\.tt" -or $fileName -Match "\.txt")
        {
            #remove any .tt or .txt files from helpers folder
            Remove-Item $file.FullName
        }
    }


    #--------------------------------------------------------------------------------------------------------------#
    #--------------------------------------------auto_install ends here--------------------------------------------#
    #--------------------------------------------------------------------------------------------------------------#
}

$project = Get-Project "$solutionName.Model"

 ForEach ($item in $project.ProjectItems) 
 { 
    if ($item.Name -eq “install.txt”)
    {
        $item.Delete()
    }
 } 

#[System.Windows.Forms.MessageBox]::Show("install.txt removed from project")
Write-Host "install.txt removed from project..."

$projectPath = Split-Path -Path $project.FullName -Parent
Remove-Item "$projectPath\in stall.txt"

#remove copy package folder
Remove-Item $installPath -Force -Recurse
#remove copy solution
Remove-Item $solutionPath_copy -Force -Recurse

[System.Windows.Forms.MessageBox]::Show("Installation complete!  Now execute all .tt files (excepte 'MultiOutput.tt') and run 'remove_templates' in the package manager console.")
Write-Host "Installation complete!"
