package com.appversal.appstorys.core.model

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull

@OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
object NullableIntSerializer : KSerializer<Int?> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("NullableInt", PrimitiveKind.INT)

    override fun deserialize(decoder: Decoder): Int? {
        val jsonDecoder = decoder as? JsonDecoder ?: return decoder.decodeInt()
        val element = jsonDecoder.decodeJsonElement()

        if (element is JsonPrimitive) {
            val content = element.contentOrNull
            if (content.isNullOrEmpty()) return null
            return content.toIntOrNull()
        }

        return null
    }

    override fun serialize(encoder: Encoder, value: Int?) {
        if (value == null) {
            encoder.encodeNull()
        } else {
            encoder.encodeInt(value)
        }
    }
}

@OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
object NullableBooleanSerializer : KSerializer<Boolean?> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("NullableBoolean", PrimitiveKind.BOOLEAN)

    override fun deserialize(decoder: Decoder): Boolean? {
        val jsonDecoder = decoder as? JsonDecoder ?: return decoder.decodeBoolean()
        val element = jsonDecoder.decodeJsonElement()

        if (element is JsonPrimitive) {
            val content = element.contentOrNull?.trim()?.lowercase() ?: return null
            return when (content) {
                "true", "1", "yes", "y" -> true
                "false", "0", "no", "n" -> false
                "", "null" -> null
                else -> null
            }
        }

        return null
    }

    override fun serialize(encoder: Encoder, value: Boolean?) {
        if (value == null) {
            encoder.encodeNull()
        } else {
            encoder.encodeBoolean(value)
        }
    }
}


