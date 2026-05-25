package com.czedr.app.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.NavigationDrawerItem
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberDrawerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.czedr.app.BuildConfig
import com.czedr.app.data.session.UserSession
import com.czedr.app.ui.theme.CzedrColors
import kotlinx.coroutines.launch
import java.text.NumberFormat
import java.util.Locale

private val fieldColors
    @Composable get() = OutlinedTextFieldDefaults.colors(
        focusedContainerColor = CzedrColors.OrangeField,
        unfocusedContainerColor = CzedrColors.OrangeField,
        focusedTextColor = CzedrColors.FieldText,
        unfocusedTextColor = CzedrColors.FieldText,
        cursorColor = CzedrColors.FieldText,
        focusedBorderColor = Color.Transparent,
        unfocusedBorderColor = Color.Transparent,
    )

@Composable
fun CzedrApp(vm: MainViewModel) {
    val session by vm.session.collectAsState()
    val nav = rememberNavController()
    if (session == null) {
        AuthNavHost(vm, nav)
    } else {
        LoggedInApp(vm, session!!, nav)
    }
}

@Composable
private fun AuthNavHost(vm: MainViewModel, nav: NavHostController) {
    NavHost(nav, startDestination = "login") {
        composable("login") {
            LoginScreen(vm, onSignUp = { nav.navigate("signup") })
        }
        composable("signup") {
            SignUpScreen(vm, onSignIn = { nav.popBackStack() })
        }
    }
}

@Composable
private fun LoggedInApp(vm: MainViewModel, session: UserSession, nav: NavHostController) {
    val drawer = rememberDrawerState(DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    val menuOpen by vm.menuOpen.collectAsState()

    LaunchedEffect(menuOpen) {
        if (menuOpen) drawer.open() else drawer.close()
    }
    LaunchedEffect(drawer.currentValue) {
        if (drawer.isClosed) vm.closeMenu()
    }

    ModalNavigationDrawer(
        drawerState = drawer,
        drawerContent = {
            ModalDrawerSheet(drawerContainerColor = CzedrColors.Surface) {
                Text(
                    "Menu",
                    modifier = Modifier.padding(24.dp),
                    color = CzedrColors.LightText,
                    fontWeight = FontWeight.Bold,
                )
                MenuItem("Home") { scope.launch { drawer.close() }; nav.navigate("home") { popUpTo("home") } }
                MenuItem("Make Payment") { scope.launch { drawer.close() }; nav.navigate("payment") }
                MenuItem("History") { scope.launch { drawer.close() }; nav.navigate("history") }
                MenuItem("Profile") { scope.launch { drawer.close() }; nav.navigate("profile") }
                if (!session.hasPinSet) {
                    MenuItem("Set PIN", accent = true) { scope.launch { drawer.close() }; nav.navigate("setpin") }
                }
                MenuItem("Send Invoice") { scope.launch { drawer.close() }; nav.navigate("placeholder/invoice") }
                MenuItem("Pending Invoices") { scope.launch { drawer.close() }; nav.navigate("placeholder/pending") }
                HorizontalDivider(Modifier.padding(vertical = 8.dp))
                MenuItem("Logout", accent = true) {
                    scope.launch { drawer.close() }
                    vm.logout()
                    nav.navigate("login") { popUpTo(0) }
                }
            }
        },
    ) {
        NavHost(nav, startDestination = "home") {
            composable("home") {
                HomeScreen(
                    vm,
                    session,
                    onMenu = { vm.openMenu() },
                    onPayment = { nav.navigate("payment") },
                    onHistory = { nav.navigate("history") },
                    onSetPin = { nav.navigate("setpin") },
                )
            }
            composable("payment") {
                MakePaymentScreen(
                    vm,
                    session,
                    onMenu = { vm.openMenu() },
                    onBack = { nav.popBackStack() },
                    onSuccess = { nav.navigate("payment_success") },
                )
            }
            composable("payment_success") {
                val home by vm.home.collectAsState()
                home.paymentSuccess?.let { details ->
                    PaymentSuccessScreen(
                        details = details,
                        onMenu = { vm.openMenu() },
                        onDone = {
                            vm.dismissHomeMessage()
                            nav.popBackStack("home", false)
                        },
                    )
                } ?: LaunchedEffect(Unit) { nav.popBackStack() }
            }
            composable("history") {
                HistoryScreen(vm, onMenu = { vm.openMenu() }, onBack = { nav.popBackStack() })
            }
            composable("profile") {
                ProfileScreen(session, vm, onMenu = { vm.openMenu() }, onBack = { nav.popBackStack() })
            }
            composable("setpin") {
                SetPinScreen(vm, onMenu = { vm.openMenu() }, onBack = { nav.popBackStack() })
            }
            composable("placeholder/{title}") { entry ->
                PlaceholderScreen(
                    title = entry.arguments?.getString("title") ?: "Coming soon",
                    onMenu = { vm.openMenu() },
                    onBack = { nav.popBackStack() },
                )
            }
        }
    }
}

@Composable
private fun MenuItem(label: String, accent: Boolean = false, onClick: () -> Unit) {
    NavigationDrawerItem(
        label = {
            Text(
                label,
                color = if (accent) CzedrColors.RedPrimary else CzedrColors.LightText,
            )
        },
        selected = false,
        onClick = onClick,
    )
}

@Composable
fun LoginScreen(vm: MainViewModel, onSignUp: () -> Unit) {
    val auth by vm.auth.collectAsState()
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var apiBase by remember { mutableStateOf(BuildConfig.API_BASE_DEFAULT.trimEnd('/')) }

    LaunchedEffect(Unit) {
        vm.discoverApi { apiBase = it }
    }

    AuthScaffold(
        title = "Czedr",
        buildLabel = vm.buildLabel,
        discoveryStatus = auth.discoveryStatus,
        error = auth.error,
        loading = auth.loading,
        apiBase = apiBase,
        onApiBaseChange = { apiBase = it; vm.clearAuthError() },
        primaryLabel = "Sign in",
        onPrimary = { vm.login(email, password, apiBase) },
        secondaryLabel = "Create account",
        onSecondary = onSignUp,
    ) {
        CzedrField("Email", email, { email = it }, KeyboardType.Email)
        Spacer(Modifier.height(12.dp))
        CzedrField("Password", password, { password = it }, KeyboardType.Password, secure = true)
    }
}

@Composable
fun SignUpScreen(vm: MainViewModel, onSignIn: () -> Unit) {
    val auth by vm.auth.collectAsState()
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirm by remember { mutableStateOf("") }
    var referrer by remember { mutableStateOf("") }
    var apiBase by remember { mutableStateOf(BuildConfig.API_BASE_DEFAULT.trimEnd('/')) }

    LaunchedEffect(Unit) {
        vm.discoverApi { apiBase = it }
    }

    AuthScaffold(
        title = "Create your Czedr account",
        buildLabel = vm.buildLabel,
        discoveryStatus = auth.discoveryStatus,
        error = auth.error,
        loading = auth.loading,
        apiBase = apiBase,
        onApiBaseChange = { apiBase = it; vm.clearAuthError() },
        primaryLabel = if (auth.loading) "Creating account…" else "Sign up",
        onPrimary = { vm.register(email, password, confirm, referrer, apiBase) },
        secondaryLabel = "Already have an account? Sign in",
        onSecondary = onSignIn,
    ) {
        CzedrField("Email", email, { email = it }, KeyboardType.Email)
        Spacer(Modifier.height(12.dp))
        CzedrField("Password (10+ characters)", password, { password = it }, KeyboardType.Password, secure = true)
        Spacer(Modifier.height(12.dp))
        CzedrField("Confirm password", confirm, { confirm = it }, KeyboardType.Password, secure = true)
        Spacer(Modifier.height(12.dp))
        CzedrField("Referrer Czedr ID (optional)", referrer, { referrer = it.uppercase() })
        Text(
            "Leave blank if no one referred you.",
            color = CzedrColors.Caption,
            fontSize = 12.sp,
            modifier = Modifier.padding(top = 4.dp),
        )
    }
}

@Composable
private fun AuthScaffold(
    title: String,
    buildLabel: String,
    discoveryStatus: String,
    error: String?,
    loading: Boolean,
    apiBase: String,
    onApiBaseChange: (String) -> Unit,
    primaryLabel: String,
    onPrimary: () -> Unit,
    secondaryLabel: String,
    onSecondary: () -> Unit,
    fields: @Composable () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(CzedrColors.Background)
            .verticalScroll(rememberScrollState())
            .padding(24.dp),
    ) {
        Text(title, color = CzedrColors.LightText, fontSize = 24.sp, fontWeight = FontWeight.Bold)
        Text(buildLabel, color = CzedrColors.Caption, fontSize = 12.sp)
        Spacer(Modifier.height(16.dp))
        CzedrField("API base URL", apiBase, onApiBaseChange, KeyboardType.Uri)
        if (discoveryStatus.isNotEmpty()) {
            Text(
                discoveryStatus,
                color = if (discoveryStatus.contains("found", true)) CzedrColors.BalanceGreen else CzedrColors.Caption,
                fontSize = 12.sp,
                modifier = Modifier.padding(top = 4.dp),
            )
        }
        Spacer(Modifier.height(16.dp))
        fields()
        error?.let {
            Spacer(Modifier.height(12.dp))
            Text(it, color = CzedrColors.RedPrimary, fontSize = 13.sp)
        }
        Spacer(Modifier.height(24.dp))
        Button(
            onClick = onPrimary,
            enabled = !loading,
            modifier = Modifier.fillMaxWidth(),
            colors = ButtonDefaults.buttonColors(containerColor = CzedrColors.CharcoalButton),
        ) {
            if (loading) CircularProgressIndicator(Modifier.width(24.dp).height(24.dp))
            else Text(primaryLabel)
        }
        TextButton(onClick = onSecondary, modifier = Modifier.align(Alignment.CenterHorizontally)) {
            Text(secondaryLabel, color = CzedrColors.Caption)
        }
    }
}

@Composable
fun HomeScreen(
    vm: MainViewModel,
    session: UserSession,
    onMenu: () -> Unit,
    onPayment: () -> Unit,
    onHistory: () -> Unit,
    onSetPin: () -> Unit,
) {
    val home by vm.home.collectAsState()
    LaunchedEffect(session.czedrId) { vm.refreshHome() }

    PageShell(title = "", onMenu = onMenu) {
        Column(Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Text(session.czedrId, color = CzedrColors.Caption)
            Text(vm.buildLabel, color = CzedrColors.Caption, fontSize = 12.sp)
            Text("Available balance", color = CzedrColors.Caption, modifier = Modifier.padding(top = 8.dp))
            Text(
                formatMoney(home.balance?.balanceCents ?: 0),
                color = CzedrColors.BalanceGreen,
                fontSize = 32.sp,
                fontWeight = FontWeight.SemiBold,
            )
            if (!session.hasPinSet) {
                Spacer(Modifier.height(12.dp))
                Card(
                    modifier = Modifier.fillMaxWidth().clickable(onClick = onSetPin),
                    colors = CardDefaults.cardColors(containerColor = CzedrColors.Surface),
                ) {
                    Text(
                        "Set your 4-digit PIN to send payments",
                        color = CzedrColors.RedPrimary,
                        modifier = Modifier.padding(12.dp),
                    )
                }
            }
            home.error?.let { Text(it, color = CzedrColors.RedPrimary, modifier = Modifier.padding(8.dp)) }
            Spacer(Modifier.height(16.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Tile("Make Payment", Modifier.weight(1f), onPayment)
                Tile("Send Invoice", Modifier.weight(1f)) { /* menu */ }
            }
            Spacer(Modifier.height(12.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Tile("Pending", Modifier.weight(1f)) {}
                Tile("History", Modifier.weight(1f), onHistory)
            }
        }
    }
}

@Composable
fun MakePaymentScreen(
    vm: MainViewModel,
    session: UserSession,
    onMenu: () -> Unit,
    onBack: () -> Unit,
    onSuccess: () -> Unit,
) {
    val home by vm.home.collectAsState()
    var recipient by remember { mutableStateOf("") }
    var amount by remember { mutableStateOf("") }
    var memo by remember { mutableStateOf("Payment") }
    var pin by remember { mutableStateOf("") }

    LaunchedEffect(home.paymentSuccess) {
        if (home.paymentSuccess != null) onSuccess()
    }

    PageShell(title = "Make Payment", onMenu = onMenu, onBack = onBack) {
        Column(Modifier.padding(16.dp)) {
            if (!session.hasPinSet) {
                Text("Set a PIN in the menu before sending money.", color = CzedrColors.RedPrimary)
                return@Column
            }
            CzedrField("Recipient Czedr ID", recipient, { recipient = it.uppercase() })
            TextButton(onClick = { vm.validateRecipient(recipient) }) { Text("Validate") }
            home.recipientLabel?.let { Text("Recipient: $it", color = CzedrColors.LightText) }
            Spacer(Modifier.height(8.dp))
            CzedrField("Amount (USD)", amount, { amount = it }, KeyboardType.Decimal)
            CzedrField("Description", memo, { memo = it })
            CzedrField("PIN", pin, { pin = it }, KeyboardType.NumberPassword, secure = true)
            home.error?.let { Text(it, color = CzedrColors.RedPrimary) }
            Spacer(Modifier.height(12.dp))
            Button(
                onClick = {
                    vm.sendTransfer(recipient, amount, memo, pin, home.recipientLabel.orEmpty())
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = !home.loading,
                colors = ButtonDefaults.buttonColors(containerColor = CzedrColors.RedPrimary),
            ) {
                Text(if (home.loading) "Sending…" else "Submit payment")
            }
        }
    }
}

@Composable
fun PaymentSuccessScreen(details: PaymentSuccessDetails, onMenu: () -> Unit, onDone: () -> Unit) {
    PageShell(title = "Success", onMenu = onMenu, showBack = false) {
        Column(
            Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Icon(Icons.Default.CheckCircle, null, tint = CzedrColors.BalanceGreen, modifier = Modifier.height(72.dp))
            Text("Payment is successful", color = CzedrColors.LightText, fontSize = 22.sp, fontWeight = FontWeight.Bold)
            Text(formatMoney(details.amountCents), color = CzedrColors.BalanceGreen, fontSize = 36.sp)
            Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(CzedrColors.Surface)) {
                Column(Modifier.padding(16.dp)) {
                    DetailRow("To", recipientLine(details))
                    if (details.memo.isNotBlank()) DetailRow("Description", details.memo)
                    details.transactionId?.takeIf { it.isNotBlank() }?.let { DetailRow("Transaction ID", it) }
                }
            }
            Spacer(Modifier.height(24.dp))
            Button(
                onClick = onDone,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(containerColor = CzedrColors.CharcoalButton),
            ) { Text("OK") }
        }
    }
}

@Composable
fun HistoryScreen(vm: MainViewModel, onMenu: () -> Unit, onBack: () -> Unit) {
    val home by vm.home.collectAsState()
    LaunchedEffect(Unit) { vm.loadHistory() }

    PageShell(title = "History", onMenu = onMenu, onBack = onBack) {
        Column(Modifier.padding(16.dp)) {
            if (home.loading) CircularProgressIndicator()
            home.history.forEach { row ->
                Card(
                    Modifier.fillMaxWidth().padding(vertical = 4.dp),
                    colors = CardDefaults.cardColors(CzedrColors.Surface),
                ) {
                    Column(Modifier.padding(12.dp)) {
                        Text(formatMoney(row.amountCents), color = CzedrColors.BalanceGreen, fontWeight = FontWeight.Bold)
                        Text("${row.fromCzedrId} → ${row.toCzedrId}", color = CzedrColors.Caption, fontSize = 12.sp)
                        if (row.memo.isNotBlank()) Text(row.memo, color = CzedrColors.LightText, fontSize = 13.sp)
                        Text(row.createdAt, color = CzedrColors.Caption, fontSize = 11.sp)
                    }
                }
            }
            if (!home.loading && home.history.isEmpty()) {
                Text("No transactions yet.", color = CzedrColors.Caption)
            }
        }
    }
}

@Composable
fun ProfileScreen(session: UserSession, vm: MainViewModel, onMenu: () -> Unit, onBack: () -> Unit) {
    PageShell(title = "Profile", onMenu = onMenu, onBack = onBack) {
        Column(Modifier.padding(16.dp)) {
            DetailRow("Email", session.email)
            DetailRow("Czedr ID", session.czedrId)
            DetailRow("PIN set", if (session.hasPinSet) "Yes" else "No")
            Spacer(Modifier.height(24.dp))
            Button(
                onClick = { vm.logout() },
                colors = ButtonDefaults.buttonColors(containerColor = CzedrColors.RedPrimary),
                modifier = Modifier.fillMaxWidth(),
            ) { Text("Sign out") }
        }
    }
}

@Composable
fun SetPinScreen(vm: MainViewModel, onMenu: () -> Unit, onBack: () -> Unit) {
    var pin by remember { mutableStateOf("") }
    var confirm by remember { mutableStateOf("") }
    val home by vm.home.collectAsState()

    PageShell(title = "Set PIN", onMenu = onMenu, onBack = onBack) {
        Column(Modifier.padding(16.dp)) {
            Text("Choose a 4-digit PIN for payments.", color = CzedrColors.Caption)
            Spacer(Modifier.height(12.dp))
            CzedrField("PIN", pin, { pin = it }, KeyboardType.NumberPassword, secure = true)
            CzedrField("Confirm PIN", confirm, { confirm = it }, KeyboardType.NumberPassword, secure = true)
            home.error?.let { Text(it, color = CzedrColors.RedPrimary) }
            Spacer(Modifier.height(16.dp))
            if (pin.isNotEmpty() && confirm.isNotEmpty() && pin != confirm) {
                Text("PINs do not match", color = CzedrColors.RedPrimary)
            }
            Button(
                onClick = { vm.setPin(pin, onBack) },
                modifier = Modifier.fillMaxWidth(),
                enabled = pin.length == 4 && pin == confirm && !home.loading,
            ) { Text("Save PIN") }
        }
    }
}

@Composable
fun PlaceholderScreen(title: String, onMenu: () -> Unit, onBack: () -> Unit) {
    PageShell(title = title, onMenu = onMenu, onBack = onBack) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text("Coming soon", color = CzedrColors.Caption)
        }
    }
}

@Composable
private fun PageShell(
    title: String,
    onMenu: () -> Unit,
    onBack: (() -> Unit)? = null,
    showBack: Boolean = onBack != null,
    content: @Composable () -> Unit,
) {
    Column(Modifier.fillMaxSize().background(CzedrColors.Background)) {
        Row(
            Modifier.fillMaxWidth().background(CzedrColors.Surface).padding(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onMenu) {
                Icon(Icons.Default.Menu, "Menu", tint = CzedrColors.LightText)
            }
            Text(
                title,
                color = CzedrColors.LightText,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier.weight(1f),
            )
            if (showBack && onBack != null) {
                IconButton(onClick = onBack) {
                    Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back", tint = CzedrColors.LightText)
                }
            } else {
                Spacer(Modifier.width(48.dp))
            }
        }
        Text(
            "CZEDR",
            color = CzedrColors.BalanceGreen,
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center,
            modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
        )
        content()
    }
}

@Composable
private fun CzedrField(
    label: String,
    value: String,
    onChange: (String) -> Unit,
    keyboard: KeyboardType = KeyboardType.Text,
    secure: Boolean = false,
) {
    Column {
        Text(label, color = CzedrColors.Caption, fontSize = 12.sp)
        OutlinedTextField(
            value = value,
            onValueChange = onChange,
            modifier = Modifier.fillMaxWidth(),
            singleLine = true,
            shape = RoundedCornerShape(4.dp),
            colors = fieldColors,
            keyboardOptions = KeyboardOptions(keyboardType = keyboard),
            visualTransformation = if (secure) PasswordVisualTransformation() else androidx.compose.ui.text.input.VisualTransformation.None,
        )
    }
}

@Composable
private fun Tile(label: String, modifier: Modifier, onClick: () -> Unit) {
    Card(
        modifier = modifier.height(80.dp).clickable(onClick = onClick),
        colors = CardDefaults.cardColors(CzedrColors.Surface),
    ) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Text(label, color = CzedrColors.LightText, textAlign = TextAlign.Center)
        }
    }
}

@Composable
private fun DetailRow(label: String, value: String) {
    Column(Modifier.padding(vertical = 4.dp)) {
        Text(label, color = CzedrColors.Caption, fontSize = 12.sp)
        Text(value, color = CzedrColors.LightText)
    }
}

private fun formatMoney(cents: Long): String {
    val dollars = cents / 100.0
    return NumberFormat.getCurrencyInstance(Locale.US).format(dollars)
}

private fun recipientLine(d: PaymentSuccessDetails): String {
    val id = d.recipientCzedrId.uppercase()
    return if (d.recipientName.isBlank() || d.recipientName.uppercase() == id) {
        id
    } else {
        "${d.recipientName} ($id)"
    }
}
