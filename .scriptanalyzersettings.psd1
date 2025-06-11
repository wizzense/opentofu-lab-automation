@{
    Rules = @{
        IncludeRules = @(
            'PSAvoidGlobalVars'
        )
        ExcludeRules = @(
            'PSUseShouldProcessForStateChangingFunctions',
            'PSAvoidUsingWriteHost'
        )
    }
}
