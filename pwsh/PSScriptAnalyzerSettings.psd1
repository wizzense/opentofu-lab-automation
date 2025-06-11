@{
    Rules = @{
        IncludeRules = @(
            'PSUseConsistentIndentation',
            'PSUseConsistentWhitespace',
            'PSPlaceOpenBrace',
            'PSPlaceCloseBrace',
            'PSAvoidTrailingWhitespace',
            'PSUseCompatibleSyntax',
            'PSAvoidUsingPlainTextForPassword',
            'PSAvoidGlobalVars'
        )
        ExcludeRules = @(
            'PSUseShouldProcessForStateChangingFunctions',
            'PSAvoidUsingWriteHost'
        )
    }
}
