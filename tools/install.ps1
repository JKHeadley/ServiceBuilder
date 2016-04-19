param($installPath, $toolsPath, $package, $project)

Write-Host "Installing...";

#--------------------------------------------------------------------------------------------------------------#
#--------------Set up variables and create an editable copy of the package/installation folder-----------------#
#--------------------------------------------------------------------------------------------------------------#

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

#--------------------------------------------------------------------------------------------------------------#
#------------------------------------Create backup of original solution----------------------------------------#
#--------------------------------------------------------------------------------------------------------------#
$from = $solutionPath
$to = $solutionPath + "_backup"
Copy-Item $from $to -recurse
$solutionPath_backup = $to
    
#--------------------------------------------------------------------------------------------------------------#
#------------------------Grab the Connection String and add logging tables to database-------------------------#
#--------------------------------------------------------------------------------------------------------------#

[xml]$proj = Get-Content "$modelPath\App.config";
$connectionString = $proj.configuration.connectionStrings.add.connectionString;

#$insert_database_tables = "$installPath\tools\insert_database_tables.ps1";

#& "$insert_database_tables" $connectionString


#[System.Windows.Forms.MessageBox]::Show("Adding logging migration and updating database.")
#& "Add-Migration" "logging" 2>&1 | Add-Content log.txt
#& "Update-Database" 2>&1 | Add-Content log.txt

#--------------------------------------------------------------------------------------------------------------#
#---------------------------------Replace stand in names with correct names------------------------------------#
#--------------------------------------------------------------------------------------------------------------#



[System.Windows.Forms.MessageBox]::Show("Replacing stand in names with correct names.")
Write-Host "Replacing stand in names with correct names..."

#replace stand in names with correct names for repository project
$files = Get-ChildItem -Path "$installPath\ServiceBuilder.Repository" -Recurse

foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { 
    $_ -replace "%SERVICEBUILDER%", $solutionName `
    } |  Set-Content $file.PSPath | Out-Null
}

foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { 
    $_ -replace "%CONNECTION_STRING%", $connectionString `
    } |  Set-Content $file.PSPath | Out-Null
}

foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { 
    $_ -replace "%SERVICE_PATH%", $servicePath `
    } |  Set-Content $file.PSPath | Out-Null
}

#WARNING: model dll path could vary on project, should find a more robust way to locate it's path
foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { 
    $_ -replace "%MODELDLL%", "$modelPath\bin\Debug\$solutionName.Model.dll" `
    
    } |  Set-Content $file.PSPath | Out-Null
}





#replace stand in names with correct names for service project
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
foreach ($file in $files)
{
    (Get-Content $file.PSPath) |
    Foreach-Object { 
    $_ -replace "%CONNECTION_STRING%", $connectionString `
    } |  Set-Content $file.PSPath | Out-Null
}


#replace stand in names with correct names for model project
$projectPath = Split-Path -Path $project.FullName -Parent
$files = Get-ChildItem -Path "$projectPath" -Recurse

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
#-------------------------------------------Fix model references ----------------------------------------------#
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

#access the repository csproj file to fix the model reference guid
$repositoryProject = Get-Project "$solutionName.Repository"
[xml]$proj = Get-Content $repositoryProject.FullName

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
$proj.Save($repositoryProject.FullName);





$project = Get-Project "$solutionName.Model"


#[System.Windows.Forms.MessageBox]::Show("install.txt removed from project")
Write-Host "install.txt removed from project..."

$projectPath = Split-Path -Path $project.FullName -Parent
Remove-Item "$projectPath\install.txt"

#remove copy package folder
Remove-Item $installPath -Force -Recurse
#remove backup solution
#Remove-Item $solutionPath_backup -Force -Recurse




[System.Windows.Forms.MessageBox]::Show("Installation complete!  Now execute all .tt files (excepte 'MultiOutput.tt') and run 'remove_templates' in the package manager console.")
Write-Host "Installation complete!"
