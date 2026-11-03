package io.nullstate.nestprep.location

import com.google.android.gms.tasks.Task
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.GeoPoint
import com.google.firebase.firestore.SetOptions
import java.util.Date

internal class FirestoreStore(
    private val firestore: FirebaseFirestore,
    private val householdId: String,
    private val memberId: String,
) : LocationStore {
    override fun setLive(fields: Map<String, Field>, done: WriteDone) =
        firestore.document(Paths.live(householdId, memberId)).set(fields.toFirestore()).report(done)

    override fun deleteLive(done: () -> Unit) {
        firestore.document(Paths.live(householdId, memberId)).delete().addOnCompleteListener { done() }
    }

    override fun mergeDay(day: String, fields: Map<String, Field>, done: WriteDone) =
        firestore.document(Paths.day(householdId, memberId, day))
            .set(fields.toFirestore(), SetOptions.merge())
            .report(done)

    override fun addEvent(fields: Map<String, Field>, done: WriteDone) =
        firestore.collection(Paths.events(householdId, memberId)).document().set(fields.toFirestore()).report(done)
}

private fun Task<Void>.report(done: WriteDone) {
    addOnCompleteListener { task ->
        done(
            when {
                task.isSuccessful -> WriteResult.Acknowledged
                (task.exception as? FirebaseFirestoreException)?.code ==
                    FirebaseFirestoreException.Code.PERMISSION_DENIED -> WriteResult.Denied
                else -> WriteResult.Failed
            },
        )
    }
}

private fun Map<String, Field>.toFirestore(): Map<String, Any> = mapValues { (_, field) ->
    when (field) {
        is Field.Point -> GeoPoint(field.latitude, field.longitude)
        Field.ServerTime -> FieldValue.serverTimestamp()
        is Field.TimeAt -> Timestamp(Date(field.epochMillis))
        is Field.Union -> FieldValue.arrayUnion(*field.items.toTypedArray())
        is Field.Value -> field.value
    }
}
