import sys

# Patch app/api/auth.py
with open("backend/app/api/auth.py", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update register function
old_reg_block = """    new_user = User(
        email=cleaned_email,
        password=hash_password(user.password),
        name=user.name,
        phone=user.phone.strip() if getattr(user, "phone", None) else None,
        role=role,
        user_type=selected_persona,
        onboarding_completed=False,
        is_verified=False
    )

    db.add(new_user)
    try:
        db.commit()
        db.refresh(new_user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Email already registered")

    # Welcome Email and Verification Email
    base_url = str(request.base_url).rstrip("/")
    token = create_verification_token(new_user.email)
    verify_link = f"{base_url}/verify-email?token={token}"
    
    # Send asynchronously so it doesn't block registration if it fails
    background_tasks.add_task(send_welcome_email, new_user.email, new_user.name or "Reader")
    background_tasks.add_task(send_verification_email, new_user.email, verify_link)

    access_token = create_access_token(data={"sub": new_user.email})

    customer_type = new_user.user_type if new_user.role == "customer" else None
    return {
        "message": "User registered successfully. Please check your email to verify your account.",
        "access_token": access_token,
        "token_type": "bearer",
        "role": new_user.role,
        "customer_type": customer_type,
        "persona": new_user.user_type or ("reader" if new_user.role == "customer" else None),
        "user_type": new_user.user_type or ("reader" if new_user.role == "customer" else None),
        "onboarding_completed": False
    }"""

new_reg_block = """    active_exp = getattr(user, "active_experience", None) or selected_persona or "reader"
    is_prov = (role == "provider")

    new_user = User(
        email=cleaned_email,
        password=hash_password(user.password),
        name=user.name,
        phone=user.phone.strip() if getattr(user, "phone", None) else None,
        role=role,
        user_type=selected_persona,
        active_experience=active_exp,
        provider_enabled=is_prov,
        provider_status="active" if is_prov else "not_enrolled",
        onboarding_completed=False,
        is_verified=False
    )

    db.add(new_user)
    try:
        db.commit()
        db.refresh(new_user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Email already registered")

    # If student provided optional academic details during signup, create StudentProfile
    if selected_persona == "student":
        from app.models.student_profile import StudentProfile
        has_academic_info = bool(user.course or user.college or user.semester)
        academic_interests = []
        if user.college:
            academic_interests.append(f"College: {user.college}")
        if user.semester:
            academic_interests.append(f"Semester: {user.semester}")
        if user.graduation_year:
            academic_interests.append(f"Graduation: {user.graduation_year}")

        sp = StudentProfile(
            user_id=new_user.id,
            course=user.course,
            college=user.college,
            semester=user.semester,
            graduation_year=user.graduation_year,
            syllabus_details=user.syllabus,
            education_level=user.semester or "Undergraduate",
            exam_goal=user.semester or "Semester Exams",
            academic_interests=json.dumps(academic_interests)
        )
        db.add(sp)
        if has_academic_info:
            new_user.onboarding_completed = True
        db.commit()

    # Welcome Email and Verification Email
    base_url = str(request.base_url).rstrip("/")
    token = create_verification_token(new_user.email)
    verify_link = f"{base_url}/verify-email?token={token}"
    
    # Send asynchronously so it doesn't block registration if it fails
    background_tasks.add_task(send_welcome_email, new_user.email, new_user.name or "Reader")
    background_tasks.add_task(send_verification_email, new_user.email, verify_link)

    access_token = create_access_token(data={"sub": new_user.email})

    customer_type = new_user.user_type if new_user.role == "customer" else None
    return {
        "message": "User registered successfully. Please check your email to verify your account.",
        "access_token": access_token,
        "token_type": "bearer",
        "role": new_user.role,
        "customer_type": customer_type,
        "persona": new_user.user_type or ("reader" if new_user.role == "customer" else None),
        "user_type": new_user.user_type or ("reader" if new_user.role == "customer" else None),
        "active_experience": new_user.active_experience or selected_persona or "reader",
        "provider_enabled": bool(getattr(new_user, "provider_enabled", False)),
        "provider_status": getattr(new_user, "provider_status", "not_enrolled") or ("active" if is_prov else "not_enrolled"),
        "onboarding_completed": bool(new_user.onboarding_completed)
    }"""

if old_reg_block in content:
    content = content.replace(old_reg_block, new_reg_block, 1)
    print("Patched register in auth.py")
else:
    print("WARNING: old_reg_block not matched in auth.py")

# 2. Update login return dict
old_login_block = """"customer_type": customer_type,
        "user_type": user.user_type or ("reader" if user.role == "customer" else None),
        "persona": user.user_type or ("reader" if user.role == "customer" else None),
        "onboarding_completed": bool(getattr(user, "onboarding_completed", False)),
        "access_token": token,"""

new_login_block = """"customer_type": customer_type,
        "user_type": user.user_type or ("reader" if user.role == "customer" else None),
        "persona": user.user_type or ("reader" if user.role == "customer" else None),
        "active_experience": user.active_experience or user.user_type or "reader",
        "provider_enabled": bool(getattr(user, "provider_enabled", False)),
        "provider_status": getattr(user, "provider_status", "not_enrolled") or "not_enrolled",
        "onboarding_completed": bool(getattr(user, "onboarding_completed", False)),
        "access_token": token,"""

if old_login_block in content:
    content = content.replace(old_login_block, new_login_block, 1)
    print("Patched login in auth.py")
else:
    print("WARNING: old_login_block not matched in auth.py")

# 3. Update google login return dict
old_google_ret = """"customer_type": customer_type,
        "user_type": user.user_type or ("reader" if user.role == "customer" else None),
        "persona": user.user_type or ("reader" if user.role == "customer" else None),
        "onboarding_completed": bool(getattr(user, "onboarding_completed", False)),
        "access_token": token,
        "token_type": "bearer"
    }"""

new_google_ret = """"customer_type": customer_type,
        "user_type": user.user_type or ("reader" if user.role == "customer" else None),
        "persona": user.user_type or ("reader" if user.role == "customer" else None),
        "active_experience": user.active_experience or user.user_type or "reader",
        "provider_enabled": bool(getattr(user, "provider_enabled", False)),
        "provider_status": getattr(user, "provider_status", "not_enrolled") or "not_enrolled",
        "onboarding_completed": bool(getattr(user, "onboarding_completed", False)),
        "access_token": token,
        "token_type": "bearer"
    }"""

if old_google_ret in content:
    content = content.replace(old_google_ret, new_google_ret, 1)
    print("Patched google_login in auth.py")
else:
    print("WARNING: old_google_ret not matched in auth.py")

# 4. Update get_profile return dict
old_prof_ret = """"role": user.role or "customer",
        "persona": user_persona,
        "user_type": user_persona
    }"""

new_prof_ret = """"role": user.role or "customer",
        "persona": user_persona,
        "user_type": user_persona,
        "active_experience": getattr(user, "active_experience", None) or user_persona,
        "provider_enabled": bool(getattr(user, "provider_enabled", False)),
        "provider_status": getattr(user, "provider_status", "not_enrolled") or "not_enrolled"
    }"""

if old_prof_ret in content:
    content = content.replace(old_prof_ret, new_prof_ret, 1)
    print("Patched get_profile in auth.py")
else:
    print("WARNING: old_prof_ret not matched in auth.py")

# 5. Append experience switching and provider activation endpoints
old_tail = """from app.schemas.user import PersonaUpdatePayload, PersonaResponse, UserResponse

@router.get("/auth/me", response_model=UserResponse)
def get_current_user_profile(user: User = Depends(get_current_user)):
    \"\"\"Retrieve currently authenticated user details including user_type and onboarding_completed.\"\"\"
    return user

@router.put("/users/me/persona", response_model=PersonaResponse)
def update_user_persona(
    payload: PersonaUpdatePayload,
    user: User = Depends(get_current_user)
):
    \"\"\"Update current user persona (student or reader) and set onboarding_completed = True.\"\"\"
    from sqlalchemy.orm import object_session
    from app.core.database import SessionLocal
    db = object_session(user) or SessionLocal()
    selected = payload.persona or payload.user_type or "reader"
    selected_val = selected.value if hasattr(selected, "value") else str(selected)
    if selected_val not in ["student", "reader"]:
        selected_val = "reader"

    user.user_type = selected_val
    user.onboarding_completed = True
    db.commit()
    db.refresh(user)
    return PersonaResponse(
        id=user.id,
        email=user.email,
        user_type=user.user_type,
        persona=user.user_type,
        onboarding_completed=user.onboarding_completed,
        role=user.role or "customer"
    )"""

new_tail = """from app.schemas.user import PersonaUpdatePayload, PersonaResponse, UserResponse, ExperienceUpdatePayload, ProviderActivationPayload

@router.get("/auth/me", response_model=UserResponse)
def get_current_user_profile(user: User = Depends(get_current_user)):
    \"\"\"Retrieve currently authenticated user details including user_type and onboarding_completed.\"\"\"
    return user

@router.put("/users/me/persona", response_model=PersonaResponse)
def update_user_persona(
    payload: PersonaUpdatePayload,
    user: User = Depends(get_current_user)
):
    \"\"\"Update current user persona (student or reader) and set onboarding_completed = True.\"\"\"
    from sqlalchemy.orm import object_session
    from app.core.database import SessionLocal
    db = object_session(user) or SessionLocal()
    selected = payload.persona or payload.user_type or payload.active_experience or "reader"
    selected_val = selected.value if hasattr(selected, "value") else str(selected)
    if selected_val not in ["student", "reader"]:
        selected_val = "reader"

    user.user_type = selected_val
    user.active_experience = selected_val
    user.onboarding_completed = True
    db.commit()
    db.refresh(user)
    return PersonaResponse(
        id=user.id,
        email=user.email,
        user_type=user.user_type,
        persona=user.user_type,
        active_experience=user.active_experience or user.user_type,
        provider_enabled=bool(user.provider_enabled),
        provider_status=user.provider_status or "not_enrolled",
        onboarding_completed=user.onboarding_completed,
        role=user.role or "customer"
    )

@router.put("/users/me/experience")
def update_user_experience(
    payload: ExperienceUpdatePayload,
    user: User = Depends(get_current_user)
):
    \"\"\"Switch active dashboard experience between student and reader without modifying data.\"\"\"
    from sqlalchemy.orm import object_session
    from app.core.database import SessionLocal
    db = object_session(user) or SessionLocal()
    exp = (payload.active_experience or "reader").strip().lower()
    if exp not in ["student", "reader"]:
        raise HTTPException(status_code=400, detail="Invalid experience. Must be 'student' or 'reader'.")
    user.active_experience = exp
    user.user_type = exp
    db.commit()
    db.refresh(user)
    return {
        "message": f"Experience switched to {exp}.",
        "active_experience": user.active_experience,
        "user_type": user.user_type,
        "provider_enabled": bool(user.provider_enabled),
        "provider_status": user.provider_status or "not_enrolled",
        "onboarding_completed": bool(user.onboarding_completed)
    }

@router.post("/provider/activate")
def activate_provider_mode(
    payload: ProviderActivationPayload = None,
    user: User = Depends(get_current_user)
):
    \"\"\"Activate provider capability for existing student or reader account without creating a second account.\"\"\"
    from sqlalchemy.orm import object_session
    from app.core.database import SessionLocal
    db = object_session(user) or SessionLocal()
    user.provider_enabled = True
    user.provider_status = "active"
    if payload:
        if payload.phone:
            user.phone = payload.phone
        if payload.address:
            user.address = payload.address
    db.commit()
    db.refresh(user)
    return {
        "message": "Provider functionality activated successfully.",
        "provider_enabled": True,
        "provider_status": "active",
        "active_experience": user.active_experience or user.user_type or "reader",
        "role": user.role
    }"""

if old_tail in content:
    content = content.replace(old_tail, new_tail, 1)
    print("Patched tail endpoints in auth.py")
else:
    print("WARNING: old_tail not matched in auth.py")

with open("backend/app/api/auth.py", "w", encoding="utf-8") as f:
    f.write(content)

print("auth.py updated successfully!")
