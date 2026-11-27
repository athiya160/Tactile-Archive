with open("backend/app/api/profile.py", "r", encoding="utf-8") as f:
    prof_code = f.read()

# 1. Update student_data in get_user_composite_profile
old_sp_block = """        student_data = {
            "id": sp.id,
            "user_id": sp.user_id,
            "education_level": sp.education_level,
            "course": sp.course,
            "subjects": parse_json_list(sp.subjects),
            "exam_goal": sp.exam_goal,
            "study_duration": sp.study_duration,
            "difficulty_level": sp.difficulty_level,
            "academic_interests": parse_json_list(sp.academic_interests),
        }"""

new_sp_block = """        student_data = {
            "id": sp.id,
            "user_id": sp.user_id,
            "education_level": sp.education_level,
            "course": sp.course,
            "college": getattr(sp, "college", None),
            "semester": getattr(sp, "semester", None),
            "graduation_year": getattr(sp, "graduation_year", None),
            "syllabus_details": getattr(sp, "syllabus_details", None),
            "subjects": parse_json_list(sp.subjects),
            "exam_goal": sp.exam_goal,
            "study_duration": sp.study_duration,
            "difficulty_level": sp.difficulty_level,
            "academic_interests": parse_json_list(sp.academic_interests),
        }"""

if old_sp_block in prof_code:
    prof_code = prof_code.replace(old_sp_block, new_sp_block, 1)
    print("Patched student_data in profile.py")

# 2. Update composite profile return dict
old_comp_ret = """        "role": user.role or "customer",
        "user_type": user.user_type or "reader",
        "persona": user.user_type or "reader",
        "onboarding_completed": bool(user.onboarding_completed),"""

new_comp_ret = """        "role": user.role or "customer",
        "user_type": user.user_type or "reader",
        "persona": user.user_type or "reader",
        "active_experience": getattr(user, "active_experience", None) or user.user_type or "reader",
        "provider_enabled": bool(getattr(user, "provider_enabled", False)),
        "provider_status": getattr(user, "provider_status", "not_enrolled") or "not_enrolled",
        "onboarding_completed": bool(user.onboarding_completed),"""

if old_comp_ret in prof_code:
    prof_code = prof_code.replace(old_comp_ret, new_comp_ret, 1)
    print("Patched get_user_composite_profile return in profile.py")

# 3. Update update_student_profile fields
old_up_sp = """    sp.education_level = payload.education_level
    sp.course = payload.course
    sp.subjects = json.dumps(payload.subjects or [])
    sp.exam_goal = payload.exam_goal
    sp.study_duration = payload.study_duration or 60
    sp.difficulty_level = payload.difficulty_level or "Intermediate"
    sp.academic_interests = json.dumps(payload.academic_interests or [])"""

new_up_sp = """    sp.education_level = payload.education_level
    sp.course = payload.course
    if getattr(payload, "college", None) is not None:
        sp.college = payload.college
    if getattr(payload, "semester", None) is not None:
        sp.semester = payload.semester
    if getattr(payload, "graduation_year", None) is not None:
        sp.graduation_year = payload.graduation_year
    if getattr(payload, "syllabus_details", None) is not None:
        sp.syllabus_details = payload.syllabus_details
    sp.subjects = json.dumps(payload.subjects or [])
    sp.exam_goal = payload.exam_goal
    sp.study_duration = payload.study_duration or 60
    sp.difficulty_level = payload.difficulty_level or "Intermediate"
    sp.academic_interests = json.dumps(payload.academic_interests or [])"""

if old_up_sp in prof_code:
    prof_code = prof_code.replace(old_up_sp, new_up_sp, 1)
    print("Patched update_student_profile body in profile.py")

old_up_sp_ret = """        "student_profile": {
            "id": sp.id,
            "user_id": sp.user_id,
            "education_level": sp.education_level,
            "course": sp.course,
            "subjects": parse_json_list(sp.subjects),
            "exam_goal": sp.exam_goal,
            "study_duration": sp.study_duration,
            "difficulty_level": sp.difficulty_level,
            "academic_interests": parse_json_list(sp.academic_interests),
        }"""

new_up_sp_ret = """        "student_profile": {
            "id": sp.id,
            "user_id": sp.user_id,
            "education_level": sp.education_level,
            "course": sp.course,
            "college": getattr(sp, "college", None),
            "semester": getattr(sp, "semester", None),
            "graduation_year": getattr(sp, "graduation_year", None),
            "syllabus_details": getattr(sp, "syllabus_details", None),
            "subjects": parse_json_list(sp.subjects),
            "exam_goal": sp.exam_goal,
            "study_duration": sp.study_duration,
            "difficulty_level": sp.difficulty_level,
            "academic_interests": parse_json_list(sp.academic_interests),
        }"""

if old_up_sp_ret in prof_code:
    prof_code = prof_code.replace(old_up_sp_ret, new_up_sp_ret, 1)
    print("Patched update_student_profile return in profile.py")

with open("backend/app/api/profile.py", "w", encoding="utf-8") as f:
    f.write(prof_code)

print("profile.py updated successfully!")

# Now patch app/api/provider.py
with open("backend/app/api/provider.py", "r", encoding="utf-8") as f:
    prov_code = f.read()

# Add require_provider helper
dep_def = """# Helper dependency to enforce provider role or activated provider status
def require_provider(user: User = Depends(get_current_user)):
    if not (user.is_admin or user.role == "provider" or getattr(user, "provider_enabled", False)):
        raise HTTPException(
            status_code=403,
            detail="Access denied. Provider mode must be activated on your account to access provider hub."
        )
    return user
"""

if "def require_provider" not in prov_code:
    prov_code = prov_code.replace("class StatusUpdatePayload(BaseModel):\n    status: str\n", "class StatusUpdatePayload(BaseModel):\n    status: str\n\n" + dep_def, 1)
    prov_code = prov_code.replace("user: User = Depends(get_current_user)", "user: User = Depends(require_provider)")
    print("Added require_provider to provider.py")

with open("backend/app/api/provider.py", "w", encoding="utf-8") as f:
    f.write(prov_code)

print("provider.py updated successfully!")
