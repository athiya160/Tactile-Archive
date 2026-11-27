import os

files_to_check = [
    'frontend/lib/features/profile/presentation/pages/profile_page.dart',
    'frontend/lib/features/account_settings/presentation/pages/account_settings_page.dart',
    'frontend/lib/core/router/app_router.dart',
    'frontend/lib/core/widgets/desktop_top_nav_bar.dart',
    'frontend/lib/core/widgets/mobile_top_nav_bar.dart',
    'frontend/lib/core/services/api_service.dart',
    'frontend/lib/features/auth/presentation/pages/register_page.dart',
    'frontend/lib/features/home/presentation/pages/reader_dashboard_page.dart',
]

def check_brackets(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        code = f.read()

    # Simple stack check ignoring strings and comments
    stack = []
    i = 0
    line = 1
    col = 1
    n = len(code)
    
    in_single_str = False
    in_double_str = False
    in_triple_single = False
    in_triple_double = False
    in_line_comment = False
    in_block_comment = False

    while i < n:
        c = code[i]
        
        if c == '\n':
            line += 1
            col = 0
            if in_line_comment:
                in_line_comment = False
            i += 1
            col += 1
            continue

        if in_line_comment:
            i += 1
            col += 1
            continue

        if in_block_comment:
            if c == '*' and i + 1 < n and code[i+1] == '/':
                in_block_comment = False
                i += 2
                col += 2
            else:
                i += 1
                col += 1
            continue

        # Check comment start
        if not in_single_str and not in_double_str and not in_triple_single and not in_triple_double:
            if c == '/' and i + 1 < n and code[i+1] == '/':
                in_line_comment = True
                i += 2
                col += 2
                continue
            if c == '/' and i + 1 < n and code[i+1] == '*':
                in_block_comment = True
                i += 2
                col += 2
                continue

        # Check triple strings
        if not in_single_str and not in_double_str:
            if c == "'" and i + 2 < n and code[i:i+3] == "'''":
                in_triple_single = not in_triple_single
                i += 3
                col += 3
                continue
            if c == '"' and i + 2 < n and code[i:i+3] == '"""':
                in_triple_double = not in_triple_double
                i += 3
                col += 3
                continue

        # Check single strings
        if not in_triple_single and not in_triple_double:
            if c == "'" and not in_double_str:
                # check escape
                if i > 0 and code[i-1] == '\\' and not (i > 1 and code[i-2] == '\\'):
                    pass
                else:
                    in_single_str = not in_single_str
                i += 1
                col += 1
                continue
            if c == '"' and not in_single_str:
                if i > 0 and code[i-1] == '\\' and not (i > 1 and code[i-2] == '\\'):
                    pass
                else:
                    in_double_str = not in_double_str
                i += 1
                col += 1
                continue

        if not in_single_str and not in_double_str and not in_triple_single and not in_triple_double:
            if c in '({[':
                stack.append((c, line, col))
            elif c in ')}]':
                if not stack:
                    return False, f"Unexpected closing '{c}' at line {line}, col {col}"
                top, t_line, t_col = stack.pop()
                expected = {')': '(', '}': '{', ']': '['}[c]
                if top != expected:
                    return False, f"Mismatched bracket: expected '{top}' (opened at {t_line}:{t_col}) to be closed, but found '{c}' at {line}:{col}"

        i += 1
        col += 1

    if stack:
        top, t_line, t_col = stack[-1]
        return False, f"Unclosed bracket '{top}' opened at line {t_line}, col {t_col}"

    return True, "OK"

for f in files_to_check:
    if os.path.exists(f):
        ok, msg = check_brackets(f)
        status = "PASSED" if ok else "FAILED"
        print(f"[{status}] {f}: {msg}")
    else:
        print(f"[MISSING] {f}")
