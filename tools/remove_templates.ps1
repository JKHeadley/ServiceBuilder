$solutionPath = Split-Path -Path $dte.Solution.FullName -Parent

$solutionName = [io.path]::GetFileNameWithoutExtension($dte.Solution.FullName)

$servicePath = "$solutionPath\$solutionName" + ".Service";
$repositoryPath = "$solutionPath\$solutionName" + ".Repository";

#--------------------------------------------------------------------------------------------------------------#
#------------------------------------------Delete temporary files----------------------------------------------#
#--------------------------------------------------------------------------------------------------------------#

#loop through and remove all references to .tt or .txt files from the csproj



#[System.Windows.Forms.MessageBox]::Show("Deleting temporary files.")
Write-Host "Deleting temporary files..."

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




$repositoryProject = Get-Project "$solutionName.Repository"
[xml]$proj = Get-Content $repositoryProject.FullName
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


$proj.Save($repositoryProject.FullName);

$files = Get-ChildItem -Path "$repositoryPath" -Recurse
foreach ($file in $files)
{
    $fileName = $file.Name
    if ($fileName -Match "\.tt" -or $fileName -Match "\.txt")
    {
        #remove any .tt or .txt files from helpers folder
        Remove-Item $file.FullName
    }
}

$project = Get-Project "$solutionName.Model"

 ForEach ($item in $project.ProjectItems) 
 { 
    if ($item.Name -eq “install.txt”)
    {
        $item.Delete()
    }
 } 

$solutionPath_backup = $solutionPath + "_backup"
#remove copy package folder
#Remove-Item $installPath -Force -Recurse
#remove backup solution
Remove-Item $solutionPath_backup -Force -Recurse


Write-Host "Installation complete!"
