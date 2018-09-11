$manifest = @{
    Path = '.\ActiveUserSetupModule.psd1'
    RootModule = 'ActiveUserSetupModule.psm1'
    Author = 'Christof Rothen'
    Copyright = 'MIT License'
    CompanyName = ''
    ModuleVersion = '1.0.0.0'
    Guid = '65f6135c-02ba-41ad-9335-375515e5ee6d'
    CmdletsToExport = ''
    VariablesToExport = ''
    AliasesToExport = ''
    FunctionsToExport = @('New-ActiveUserSetupTask', 'Set-ActiveUserSetupTask', 'Test-ActiveUserSetupTask', 'Remove-ActiveUserSetupTask')
}

New-ModuleManifest @manifest