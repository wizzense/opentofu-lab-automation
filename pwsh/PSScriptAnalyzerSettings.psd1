@{
    IncludeRules = @(
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'PSAvoidTrailingWhitespace',
        'PSUseCompatibleSyntax'
    )
    ExcludeRules = @(
        'PSUseShouldProcessForStateChangingFunctions',
        'PSAvoidUsingWriteHost',
        'PSAvoidGlobalVars',
        'PSAvoidUsingPlainTextForPassword'
    )
}
