#[System.Windows.Forms.MessageBox]::Show("Adding logging migration and updating database.")

& "Add-Migration" "ServiceBuilder_LogEvents"
& "Update-Database"