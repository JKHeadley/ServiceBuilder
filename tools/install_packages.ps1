#--------------------------------------------------------------------------------------------------------------#
#------------------------------------------Re-install nuget packages-------------------------------------------#
#--------------------------------------------------------------------------------------------------------------#


$solutionName = [io.path]::GetFileNameWithoutExtension($dte.Solution.FullName)

$msbuild = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe"

$projects = Get-Project -All

foreach($proj in $projects)
{
 $projName = $proj.Name
 if ($projName -eq "$solutionName.Repository" -or $projName -eq "$solutionName.Service")
 {
     Write-Host "Processing project $projName..."
     #[System.Windows.Forms.MessageBox]::Show("Processing project $projName...") 

     $path = Join-Path (Split-Path $proj.FileName) packages.config

     if(Test-Path $path)
     {
      Write-Host "Processing $path..."
      #[System.Windows.Forms.MessageBox]::Show("Processing $path...") 

      $xml = [xml]$packages = Get-Content $path
      foreach($package in $packages.packages.package)
      {
       $id = $package.id
       if ($id -ne "CAPS_ServiceBuilder") 
       {
           Write-Host "Installing package $id..."   
           #[System.Windows.Forms.MessageBox]::Show("Installing package $id...")   
           #Install-Package -Id $id -Version $package.version
           Update-Package -Id $id -ProjectName $projName -Reinstall
       }
      }
     }

     & $msbuild $proj.FullName /p:Configuration=Debug
 }
}

& $msbuild $dte.Solution.FullName /p:Configuration=Debug
#--------------------------------------------------------------------------------------------------------------#
#------------------------------------------Resolve project references------------------------------------------#
#--------------------------------------------------------------------------------------------------------------#


