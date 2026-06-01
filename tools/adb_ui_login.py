import subprocess, xml.etree.ElementTree as ET, re, time

ADB = r"C:\Users\DELL\AppData\Local\Android\Sdk\platform-tools\adb.exe"
USERID = 'e2euser'
PASSWORD = 'Pass1234!'

def adb(cmd):
    full = [ADB] + cmd
    return subprocess.check_output(full, shell=False)


def dump_ui():
    out = adb(['exec-out', 'uiautomator', 'dump', '/dev/tty'])
    return out.decode('utf-8', errors='replace')


def parse_bounds(bounds_str):
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds_str)
    if not m:
        return None
    x1, y1, x2, y2 = map(int, m.groups())
    return ((x1 + x2) // 2, (y1 + y2) // 2)


def find_node(root, test_fn):
    for node in root.iter('node'):
        if test_fn(node.attrib):
            return node
    return None


def safe_text_for_adb(s):
    # adb input text expects special chars encoded like %21 for '!'
    # Minimal encoding for common special chars
    mapping = {'!':'%21','%':'%25','@':'%40','#':'%23','$':'%24','^':'%5E','&':'%26','*':'%2A','(':'%28',')':'%29','<':'%3C','>':'%3E',' ':'%s'}
    out = []
    for ch in s:
        out.append(mapping.get(ch, ch))
    return ''.join(out)


def tap(x,y):
    adb(['shell','input','tap',str(x),str(y)])


def input_text(s):
    adb(['shell','input','text', safe_text_for_adb(s)])


def main():
    print('Ensuring app is running...')
    try:
        adb(['shell','am','start','-n','com.example.cryptosafe_mobile/.MainActivity'])
    except Exception:
        pass
    time.sleep(0.6)
    print('Dumping UI...')
    xml = dump_ui()
    # extract the first <hierarchy>..</hierarchy> block from adb output
    start = xml.find('<hierarchy')
    end = xml.rfind('</hierarchy>')
    if start == -1 or end == -1:
        print('Failed to find XML hierarchy in uiautomator output')
        print(xml[:2000])
        return
    xml_block = xml[start:end + len('</hierarchy>')]
    try:
        root = ET.fromstring(xml_block)
    except ET.ParseError as e:
        print('XML parse error:', e)
        print('XML snippet:', xml_block[:2000])
        return

    # find Login screen fields
    user_node = find_node(root, lambda a: (a.get('class')=='android.widget.EditText' and (a.get('hint') or '').lower().startswith('user')))
    pass_node = find_node(root, lambda a: (a.get('class')=='android.widget.EditText' and (a.get('hint') or '').lower().startswith('pass')))
    login_btn = find_node(root, lambda a: (a.get('class') and 'Button' in a.get('class') and (a.get('content-desc') or a.get('text') or '').strip().lower()=='login'))

    if not user_node or not pass_node:
        print('User/password not found; trying to open Login from home screen...')
        # try find a Login button and tap it
        login_btn_home = find_node(root, lambda a: (a.get('content-desc') or '').strip().lower() == 'login' or (a.get('text') or '').strip().lower() == 'login')
        if login_btn_home is not None:
            b = parse_bounds(login_btn_home.attrib.get('bounds'))
            if b:
                tap(*b)
                time.sleep(0.6)
                xml = dump_ui()
                start = xml.find('<hierarchy')
                end = xml.rfind('</hierarchy>')
                if start != -1 and end != -1:
                    xml_block = xml[start:end + len('</hierarchy>')]
                    try:
                        root = ET.fromstring(xml_block)
                    except ET.ParseError:
                        print('Failed to parse UI after tapping Login')
                        return
                    user_node = find_node(root, lambda a: (a.get('class')=='android.widget.EditText' and (a.get('hint') or '').lower().startswith('user')))
                    pass_node = find_node(root, lambda a: (a.get('class')=='android.widget.EditText' and (a.get('hint') or '').lower().startswith('pass')))
        if not user_node or not pass_node:
            # handle possible system dialog (ANR) by tapping 'Wait' or 'Close app'
            dlg_wait = find_node(root, lambda a: (a.get('text') or '').strip().lower() == 'wait' or (a.get('content-desc') or '').strip().lower() == 'wait')
            dlg_close = find_node(root, lambda a: (a.get('text') or '').strip().lower() == 'close app' or (a.get('content-desc') or '').strip().lower() == 'close app')
            if dlg_wait is not None:
                b = parse_bounds(dlg_wait.attrib.get('bounds'))
                if b:
                    print('Dismissing ANR dialog: tapping Wait at', b)
                    tap(*b); time.sleep(0.6)
                    xml = dump_ui()
                    start = xml.find('<hierarchy')
                    end = xml.rfind('</hierarchy>')
                    if start != -1 and end != -1:
                        xml_block = xml[start:end + len('</hierarchy>')]
                        try:
                            root = ET.fromstring(xml_block)
                        except ET.ParseError:
                            return
                        user_node = find_node(root, lambda a: (a.get('class')=='android.widget.EditText' and (a.get('hint') or '').lower().startswith('user')))
                        pass_node = find_node(root, lambda a: (a.get('class')=='android.widget.EditText' and (a.get('hint') or '').lower().startswith('pass')))
            elif dlg_close is not None:
                b = parse_bounds(dlg_close.attrib.get('bounds'))
                if b:
                    print('Dismissing ANR dialog: tapping Close app at', b)
                    tap(*b); time.sleep(0.6)
                    xml = dump_ui()
                    start = xml.find('<hierarchy')
                    end = xml.rfind('</hierarchy>')
                    if start != -1 and end != -1:
                        xml_block = xml[start:end + len('</hierarchy>')]
                        try:
                            root = ET.fromstring(xml_block)
                        except ET.ParseError:
                            return
                        user_node = find_node(root, lambda a: (a.get('class')=='android.widget.EditText' and (a.get('hint') or '').lower().startswith('user')))
                        pass_node = find_node(root, lambda a: (a.get('class')=='android.widget.EditText' and (a.get('hint') or '').lower().startswith('pass')))
            print('Still could not locate user/password fields. Dumping nodes for inspection...')
            for n in root.iter('node'):
                cl = n.attrib.get('class','')
                hint = n.attrib.get('hint','')
                cd = n.attrib.get('content-desc','')
                txt = n.attrib.get('text','')
                if cl.endswith('EditText') or 'Button' in cl:
                    print(cl, 'hint=', hint, 'cd=', cd, 'text=', txt, 'bounds=', n.attrib.get('bounds'))
            return

    ux = parse_bounds(user_node.attrib.get('bounds'))
    px = parse_bounds(pass_node.attrib.get('bounds'))
    bx = parse_bounds(login_btn.attrib.get('bounds')) if login_btn is not None else None

    print('Tapping User field at', ux)
    tap(*ux); time.sleep(0.2)
    input_text(USERID); time.sleep(0.4)

    print('Tapping Password field at', px)
    tap(*px); time.sleep(0.2)
    input_text(PASSWORD); time.sleep(0.4)

    if bx:
        print('Tapping Login button at', bx)
        tap(*bx)
    else:
        print('Login button not found; attempting coordinate fallback')
        # attempt to tap center-bottom default
        tap(540,2000)

    time.sleep(1)
    print('Final UI dump:')
    print(dump_ui()[:4000])

if __name__=='__main__':
    main()
