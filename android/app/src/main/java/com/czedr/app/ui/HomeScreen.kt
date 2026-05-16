package com.czedr.app.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import com.czedr.app.data.session.UserSession

@Composable
fun HomeScreen(
    session: UserSession,
    state: HomeUiState,
    onRefresh: () -> Unit,
    onLogout: () -> Unit,
    onValidate: (czedrId: String) -> Unit,
    onSendTransfer: (to: String, amount: String, memo: String, pin: String) -> Unit,
    onDismissMessage: () -> Unit,
) {
    var recipient by remember { mutableStateOf("") }
    var amount by remember { mutableStateOf("") }
    var memo by remember { mutableStateOf("Payment") }
    var pin by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(20.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column {
                Text("Signed in", style = MaterialTheme.typography.labelMedium)
                Text(session.email.ifBlank { session.czedrId }, style = MaterialTheme.typography.titleMedium)
                Text(
                    "ID: ${session.czedrId}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            TextButton(onClick = onLogout) { Text("Sign out") }
        }
        Spacer(Modifier.height(16.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            OutlinedButton(onClick = onRefresh, modifier = Modifier.weight(1f), enabled = !state.loading) {
                Text(if (state.loading) "…" else "Refresh")
            }
        }

        state.error?.let {
            Spacer(Modifier.height(8.dp))
            Text(it, color = MaterialTheme.colorScheme.error)
        }
        state.actionMessage?.let {
            Spacer(Modifier.height(8.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(it, color = MaterialTheme.colorScheme.primary)
                TextButton(onClick = onDismissMessage) { Text("OK") }
            }
        }

        Spacer(Modifier.height(16.dp))
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(),
        ) {
            Column(Modifier.padding(16.dp)) {
                Text("Balance", style = MaterialTheme.typography.titleSmall)
                val bal = state.balance
                if (bal == null) {
                    Text("—")
                } else {
                    Text(
                        "${"%.2f".format(bal.balanceCents / 100.0)} ${bal.currency}",
                        style = MaterialTheme.typography.headlineSmall,
                    )
                    Text(
                        "Transfer fee: ${"%.2f".format(bal.transferFeeCents / 100.0)} | Referral reward: ${"%.2f".format(bal.referralRewardCents / 100.0)}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }

        Spacer(Modifier.height(12.dp))
        Card(modifier = Modifier.fillMaxWidth()) {
            Column(Modifier.padding(16.dp)) {
                Text("Referral earnings", style = MaterialTheme.typography.titleSmall)
                val ref = state.referrals
                if (ref == null) {
                    Text("—")
                } else {
                    Text(
                        "Total: ${"%.2f".format(ref.totalCents / 100.0)} ${ref.currency} (${ref.paymentCount} payments)",
                        style = MaterialTheme.typography.bodyLarge,
                    )
                    if (ref.recent.isNotEmpty()) {
                        Spacer(Modifier.height(8.dp))
                        Text("Recent", style = MaterialTheme.typography.labelMedium)
                        ref.recent.take(5).forEach { row ->
                            Text(
                                "${"%.2f".format(row.amountCents / 100.0)} · ${row.createdAt}",
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                    }
                }
            }
        }

        Spacer(Modifier.height(16.dp))
        Text("Send transfer", style = MaterialTheme.typography.titleMedium)
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = recipient,
            onValueChange = { recipient = it.uppercase() },
            label = { Text("Recipient Czedr ID") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            TextButton(
                onClick = { onValidate(recipient) },
                enabled = recipient.isNotBlank(),
            ) { Text("Validate") }
        }
        state.recipientLabel?.let { label ->
            Text("Recipient: $label", style = MaterialTheme.typography.bodyMedium)
            Spacer(Modifier.height(8.dp))
        }

        OutlinedTextField(
            value = amount,
            onValueChange = { amount = it },
            label = { Text("Amount (USD)") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
        )
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = memo,
            onValueChange = { memo = it },
            label = { Text("Memo") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
        )
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = pin,
            onValueChange = { pin = it },
            label = { Text("PIN") },
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
        )
        Spacer(Modifier.height(12.dp))
        Button(
            onClick = { onSendTransfer(recipient, amount, memo, pin) },
            modifier = Modifier.fillMaxWidth(),
            enabled = recipient.isNotBlank() && amount.isNotBlank() && pin.isNotBlank(),
        ) {
            Text("Send")
        }
        Spacer(Modifier.height(24.dp))
        HorizontalDivider()
        Text(
            "Transfers require your account PIN (same as iOS).",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
