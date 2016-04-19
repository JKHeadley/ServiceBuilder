param($installPath, $toolsPath, $package, $project)

 ForEach ($item in $project.ProjectItems) 
 { 
    if ($item.Name -eq “LoggingConfiguration_PrimaryKeys.tt” `
    -or $item.Name -eq “LoggingConfiguration_User.tt” `
    -or $item.Name -eq “MultiOutput.tt” `
    -or $item.Name -eq “LoggingDecorator.tt”)
    {
        $item.Delete()
    }
 } 

$content = Split-Path -Path $project.FullName -Parent

Remove-Item "$content\LoggingConfiguration_PrimaryKeys.tt"
Remove-Item "$content\LoggingConfiguration_PrimaryKeys.cs"
Remove-Item "$content\LoggingConfiguration_PrimaryKeys.xml"
Remove-Item "$content\LoggingConfiguration_PrimaryKeys.txt"

Remove-Item "$content\LoggingConfiguration_User.tt"
Remove-Item "$content\LoggingConfiguration_User.cs"
Remove-Item "$content\LoggingConfiguration_User.xml"
Remove-Item "$content\LoggingConfiguration_User.txt"

Remove-Item "$content\MultiOutput.tt"
Remove-Item "$content\MultiOutput.cs"
Remove-Item "$content\MultiOutput.txt"

Remove-Item "$content\LogEvent.cs"
Remove-Item "$content\LogEventType.cs"
Remove-Item "$content\LoggingDecorator.txt"

