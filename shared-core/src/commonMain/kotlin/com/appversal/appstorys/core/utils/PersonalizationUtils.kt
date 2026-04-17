package com.appversal.appstorys.core.utils

fun personalizeText(text: String, personalizationData: Map<String, String>): String {
    if (text.isBlank()) return text

    if (personalizationData.isEmpty()) {
        return replacePlaceholdersWithFallback(text)
    }

    val regex = """\{\{([^|}\s]+)\s*\|\s*([^}]+)\}\}""".toRegex()

    return regex.replace(text) { matchResult ->
        val variableName = matchResult.groupValues[1].trim()
        val fallbackValue = matchResult.groupValues[2].trim()
        personalizationData[variableName] ?: fallbackValue
    }
}

private fun replacePlaceholdersWithFallback(text: String): String {
    val regex = """\{\{[^|}\s]+\s*\|\s*([^}]+)\}\}""".toRegex()
    return regex.replace(text) { matchResult ->
        matchResult.groupValues[1].trim()
    }
}