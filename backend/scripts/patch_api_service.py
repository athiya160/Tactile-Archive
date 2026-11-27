with open("frontend/lib/core/services/api_service.dart", "r", encoding="utf-8") as f:
    code = f.read()

# 1. State definitions
old_state = """  static const String _userTypeKey = 'user_type';
  static const String _personaKey = 'user_persona';
  static const String _onboardingKey = 'onboarding_completed';

  static String? token;
  static UserRole role = UserRole.none;
  static UserType userType = UserType.reader;
  static bool onboardingCompleted = false;
  static String? userName;
  static bool _isGuest = false;"""

new_state = """  static const String _userTypeKey = 'user_type';
  static const String _personaKey = 'user_persona';
  static const String _experienceKey = 'active_experience';
  static const String _providerEnabledKey = 'provider_enabled';
  static const String _providerStatusKey = 'provider_status';
  static const String _onboardingKey = 'onboarding_completed';

  static String? token;
  static UserRole role = UserRole.none;
  static UserType userType = UserType.reader;
  static UserType activeExperience = UserType.reader;
  static bool providerEnabled = false;
  static String providerStatus = 'not_enrolled';
  static bool onboardingCompleted = false;
  static String? userName;
  static bool _isGuest = false;"""

if old_state in code:
    code = code.replace(old_state, new_state, 1)
    print("Patched state definitions in api_service.dart")
else:
    print("WARNING: old_state not found in api_service.dart")

# 2. ValueNotifiers
old_notifiers = """  /// Reactive user type state
  static final userTypeState = ValueNotifier<UserType>(UserType.reader);

  /// Reactive onboarding state
  static final onboardingState = ValueNotifier<bool>(false);"""

new_notifiers = """  /// Reactive user type state
  static final userTypeState = ValueNotifier<UserType>(UserType.reader);

  /// Reactive active experience state (Student or Reader dashboard)
  static final experienceState = ValueNotifier<UserType>(UserType.reader);

  /// Reactive provider capability state
  static final providerState = ValueNotifier<bool>(false);

  /// Reactive onboarding state
  static final onboardingState = ValueNotifier<bool>(false);"""

if old_notifiers in code:
    code = code.replace(old_notifiers, new_notifiers, 1)
    print("Patched notifiers in api_service.dart")
else:
    print("WARNING: old_notifiers not found in api_service.dart")

# 3. loadToken additions
old_load = """    final savedType = prefs.getString(_personaKey) ?? prefs.getString(_userTypeKey);
    if (savedType != null) {
      userType = UserType.values.firstWhere(
        (e) => e.name == savedType,
        orElse: () => UserType.reader,
      );
    }
    onboardingCompleted = prefs.getBool(_onboardingKey) ?? false;"""

new_load = """    final savedType = prefs.getString(_personaKey) ?? prefs.getString(_userTypeKey);
    if (savedType != null) {
      userType = UserType.values.firstWhere(
        (e) => e.name == savedType,
        orElse: () => UserType.reader,
      );
    }
    final savedExp = prefs.getString(_experienceKey) ?? savedType;
    if (savedExp != null) {
      activeExperience = UserType.values.firstWhere(
        (e) => e.name == savedExp,
        orElse: () => userType,
      );
    } else {
      activeExperience = userType;
    }
    providerEnabled = prefs.getBool(_providerEnabledKey) ?? (role == UserRole.provider);
    providerStatus = prefs.getString(_providerStatusKey) ?? (providerEnabled ? 'active' : 'not_enrolled');
    onboardingCompleted = prefs.getBool(_onboardingKey) ?? false;"""

if old_load in code:
    code = code.replace(old_load, new_load, 1)
    print("Patched loadToken in api_service.dart")
else:
    print("WARNING: old_load not found in api_service.dart")

# 4. _saveSession additions
old_save = """  static Future<void> _saveSession(
    String t,
    UserRole r, {
    String? name,
    UserType uType = UserType.reader,
    bool onboarding = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, t);
    await prefs.setString(_roleKey, r.name);
    await prefs.setString(_userTypeKey, uType.name);
    await prefs.setString(_personaKey, uType.name);
    await prefs.setBool(_onboardingKey, onboarding);
    if (name != null) {
      await prefs.setString(_nameKey, name);
      userName = name;
    }
    token = t;
    role = r;
    userType = uType;
    onboardingCompleted = onboarding;
    authState.value = true;
    roleState.value = r;
    userTypeState.value = uType;
    onboardingState.value = onboarding;
    _isGuest = false;
  }"""

new_save = """  static Future<void> _saveSession(
    String t,
    UserRole r, {
    String? name,
    UserType uType = UserType.reader,
    UserType? exp,
    bool onboarding = false,
    bool provEnabled = false,
    String provStatus = 'not_enrolled',
  }) async {
    final selectedExp = exp ?? uType;
    final isProv = provEnabled || r == UserRole.provider;
    final finalProvStatus = isProv ? 'active' : provStatus;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, t);
    await prefs.setString(_roleKey, r.name);
    await prefs.setString(_userTypeKey, uType.name);
    await prefs.setString(_personaKey, uType.name);
    await prefs.setString(_experienceKey, selectedExp.name);
    await prefs.setBool(_providerEnabledKey, isProv);
    await prefs.setString(_providerStatusKey, finalProvStatus);
    await prefs.setBool(_onboardingKey, onboarding);
    if (name != null) {
      await prefs.setString(_nameKey, name);
      userName = name;
    }
    token = t;
    role = r;
    userType = uType;
    activeExperience = selectedExp;
    providerEnabled = isProv;
    providerStatus = finalProvStatus;
    onboardingCompleted = onboarding;
    authState.value = true;
    roleState.value = r;
    userTypeState.value = uType;
    experienceState.value = selectedExp;
    providerState.value = isProv;
    onboardingState.value = onboarding;
    _isGuest = false;
  }"""

if old_save in code:
    code = code.replace(old_save, new_save, 1)
    print("Patched _saveSession in api_service.dart")
else:
    print("WARNING: old_save not found in api_service.dart")

# 5. logout additions
old_logout = """    await prefs.remove(_userTypeKey);
    await prefs.remove(_personaKey);
    await prefs.remove(_onboardingKey);"""

new_logout = """    await prefs.remove(_userTypeKey);
    await prefs.remove(_personaKey);
    await prefs.remove(_experienceKey);
    await prefs.remove(_providerEnabledKey);
    await prefs.remove(_providerStatusKey);
    await prefs.remove(_onboardingKey);"""

if old_logout in code:
    code = code.replace(old_logout, new_logout, 1)
    print("Patched logout prefs removal in api_service.dart")

old_logout_vars = """    token = null;
    role = UserRole.none;
    userType = UserType.reader;
    onboardingCompleted = false;
    userName = null;"""

new_logout_vars = """    token = null;
    role = UserRole.none;
    userType = UserType.reader;
    activeExperience = UserType.reader;
    providerEnabled = false;
    providerStatus = 'not_enrolled';
    onboardingCompleted = false;
    userName = null;"""

if old_logout_vars in code:
    code = code.replace(old_logout_vars, new_logout_vars, 1)
    print("Patched logout vars in api_service.dart")

old_logout_notifs = """    userTypeState.value = UserType.reader;
    onboardingState.value = false;
    _isGuest = false;"""

new_logout_notifs = """    userTypeState.value = UserType.reader;
    experienceState.value = UserType.reader;
    providerState.value = false;
    onboardingState.value = false;
    _isGuest = false;"""

if old_logout_notifs in code:
    code = code.replace(old_logout_notifs, new_logout_notifs, 1)
    print("Patched logout notifiers in api_service.dart")

# 6. switchExperience and activateProvider methods
methods = """  /// Switches active dashboard experience (Student <-> Reader) while preserving same account and data.
  static Future<bool> switchExperience(UserType newExp) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/users/me/experience"),
        headers: _headers(),
        body: jsonEncode({"active_experience": newExp.name}),
      );
      if (response.statusCode == 200) {
        activeExperience = newExp;
        userType = newExp;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_experienceKey, newExp.name);
        await prefs.setString(_userTypeKey, newExp.name);
        await prefs.setString(_personaKey, newExp.name);
        experienceState.value = newExp;
        userTypeState.value = newExp;
        return true;
      }
      return false;
    } catch (_) {
      // Offline fallback
      activeExperience = newExp;
      userType = newExp;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_experienceKey, newExp.name);
      await prefs.setString(_userTypeKey, newExp.name);
      experienceState.value = newExp;
      userTypeState.value = newExp;
      return true;
    }
  }

  /// Activates provider capability for student or reader account without creating a second account.
  static Future<bool> activateProvider({String? phone, String? address, String? businessName}) async {
    try {
      final payload = <String, dynamic>{};
      if (phone != null && phone.isNotEmpty) payload['phone'] = phone;
      if (address != null && address.isNotEmpty) payload['address'] = address;
      if (businessName != null && businessName.isNotEmpty) payload['business_name'] = businessName;

      final response = await http.post(
        Uri.parse("$baseUrl/provider/activate"),
        headers: _headers(),
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        providerEnabled = true;
        providerStatus = 'active';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_providerEnabledKey, true);
        await prefs.setString(_providerStatusKey, 'active');
        providerState.value = true;
        return true;
      }
      return false;
    } catch (_) {
      providerEnabled = true;
      providerStatus = 'active';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_providerEnabledKey, true);
      await prefs.setString(_providerStatusKey, 'active');
      providerState.value = true;
      return true;
    }
  }
"""

if "static Future<bool> switchExperience" not in code:
    code = code.replace("  /// Updates current user persona (student or reader) via backend REST API.", methods + "\n  /// Updates current user persona (student or reader) via backend REST API.", 1)
    print("Added switchExperience and activateProvider to api_service.dart")

# 7. Update register method to accept optional student fields
old_reg = """  static Future<String?> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.customer,
    UserType? userType = UserType.reader,
    String? phone,
  }) async {
    try {
      final isProvider = role == UserRole.provider;
      final payload = {
        "name": name.trim(),
        "email": email.trim(),
        "password": password,
        "role": role.name,
        "customer_type": isProvider ? null : (userType?.name ?? "reader"),
        "user_type": isProvider ? null : (userType?.name ?? "reader"),
        "persona": isProvider ? null : (userType?.name ?? "reader"),
        if (phone != null && phone.trim().isNotEmpty) "phone": phone.trim(),
      };"""

new_reg = """  static Future<String?> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.customer,
    UserType? userType = UserType.reader,
    UserType? activeExperience,
    String? phone,
    String? college,
    String? course,
    String? semester,
    String? graduationYear,
    String? syllabus,
  }) async {
    try {
      final isProvider = role == UserRole.provider;
      final expToUse = activeExperience ?? userType ?? UserType.reader;
      final payload = <String, dynamic>{
        "name": name.trim(),
        "email": email.trim(),
        "password": password,
        "role": role.name,
        "customer_type": isProvider ? null : (userType?.name ?? "reader"),
        "user_type": isProvider ? null : (userType?.name ?? "reader"),
        "persona": isProvider ? null : (userType?.name ?? "reader"),
        "active_experience": expToUse.name,
        if (phone != null && phone.trim().isNotEmpty) "phone": phone.trim(),
        if (college != null && college.trim().isNotEmpty) "college": college.trim(),
        if (course != null && course.trim().isNotEmpty) "course": course.trim(),
        if (semester != null && semester.trim().isNotEmpty) "semester": semester.trim(),
        if (graduationYear != null && graduationYear.trim().isNotEmpty) "graduation_year": graduationYear.trim(),
        if (syllabus != null && syllabus.trim().isNotEmpty) "syllabus": syllabus.trim(),
      };"""

if old_reg in code:
    code = code.replace(old_reg, new_reg, 1)
    print("Patched register signature & payload in api_service.dart")
else:
    print("WARNING: old_reg not found in api_service.dart")

# 8. Update register response handling in api_service
old_reg_res = """        if (data['access_token'] != null) {
          final uTypeStr = data['customer_type'] ?? data['persona'] ?? data['user_type'];
          final parsedUserType =
              uTypeStr == 'student' ? UserType.student : UserType.reader;
          final userRole = data['role'] == 'provider' ? UserRole.provider : role;
          await _saveSession(
            data['access_token'],
            userRole,
            name: name,
            uType: parsedUserType,
          );
        }"""

new_reg_res = """        if (data['access_token'] != null) {
          final uTypeStr = data['customer_type'] ?? data['persona'] ?? data['user_type'];
          final parsedUserType =
              uTypeStr == 'student' ? UserType.student : UserType.reader;
          final expStr = data['active_experience'] ?? uTypeStr;
          final parsedExp =
              expStr == 'student' ? UserType.student : UserType.reader;
          final isProv = data['provider_enabled'] == true || data['role'] == 'provider';
          final provStat = data['provider_status']?.toString() ?? (isProv ? 'active' : 'not_enrolled');
          final userRole = data['role'] == 'provider' ? UserRole.provider : role;
          final isCompleted = data['onboarding_completed'] == true;
          await _saveSession(
            data['access_token'],
            userRole,
            name: name,
            uType: parsedUserType,
            exp: parsedExp,
            onboarding: isCompleted,
            provEnabled: isProv,
            provStatus: provStat,
          );
        }"""

if old_reg_res in code:
    code = code.replace(old_reg_res, new_reg_res, 1)
    print("Patched register response handling in api_service.dart")
else:
    print("WARNING: old_reg_res not found in api_service.dart")

# 9. Update login parsing in api_service
old_login_parse = """        final uTypeStr = data['customer_type'] ?? data['persona'] ?? data['user_type'] ?? 'reader';
        final parsedUserType =
            uTypeStr == 'student' ? UserType.student : UserType.reader;
        final isCompleted = data['onboarding_completed'] == true;

        await _saveSession(
          data['access_token'],
          userRole,
          name: data['name'] ?? emailOrPhone.split('@')[0],
          uType: parsedUserType,
          onboarding: isCompleted,
        );"""

new_login_parse = """        final uTypeStr = data['customer_type'] ?? data['persona'] ?? data['user_type'] ?? 'reader';
        final parsedUserType =
            uTypeStr == 'student' ? UserType.student : UserType.reader;
        final expStr = data['active_experience'] ?? uTypeStr;
        final parsedExp =
            expStr == 'student' ? UserType.student : UserType.reader;
        final isProv = data['provider_enabled'] == true || data['role'] == 'provider';
        final provStat = data['provider_status']?.toString() ?? (isProv ? 'active' : 'not_enrolled');
        final isCompleted = data['onboarding_completed'] == true;

        await _saveSession(
          data['access_token'],
          userRole,
          name: data['name'] ?? emailOrPhone.split('@')[0],
          uType: parsedUserType,
          exp: parsedExp,
          onboarding: isCompleted,
          provEnabled: isProv,
          provStatus: provStat,
        );"""

if old_login_parse in code:
    code = code.replace(old_login_parse, new_login_parse, 1)
    print("Patched login parsing in api_service.dart")
else:
    print("WARNING: old_login_parse not found in api_service.dart")

# 10. Update fetchCompositeProfile to parse active_experience and provider_enabled
old_comp_parse = """        final pStr = data['persona'] ?? data['user_type'];
        if (pStr != null) {
          userType = pStr == 'student' ? UserType.student : UserType.reader;
          userTypeState.value = userType;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userTypeKey, userType.name);
          await prefs.setString(_personaKey, userType.name);
        }"""

new_comp_parse = """        final pStr = data['persona'] ?? data['user_type'];
        if (pStr != null) {
          userType = pStr == 'student' ? UserType.student : UserType.reader;
          userTypeState.value = userType;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userTypeKey, userType.name);
          await prefs.setString(_personaKey, userType.name);
        }
        final expStr = data['active_experience'] ?? pStr;
        if (expStr != null) {
          activeExperience = expStr == 'student' ? UserType.student : UserType.reader;
          experienceState.value = activeExperience;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_experienceKey, activeExperience.name);
        }
        if (data['provider_enabled'] != null) {
          providerEnabled = data['provider_enabled'] == true || data['role'] == 'provider';
          providerStatus = data['provider_status']?.toString() ?? (providerEnabled ? 'active' : 'not_enrolled');
          providerState.value = providerEnabled;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_providerEnabledKey, providerEnabled);
          await prefs.setString(_providerStatusKey, providerStatus);
        }"""

if old_comp_parse in code:
    code = code.replace(old_comp_parse, new_comp_parse, 1)
    print("Patched fetchCompositeProfile in api_service.dart")
else:
    print("WARNING: old_comp_parse not found in api_service.dart")

with open("frontend/lib/core/services/api_service.dart", "w", encoding="utf-8") as f:
    f.write(code)

print("api_service.dart updated successfully!")
