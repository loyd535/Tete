import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


// ════════ theme ════════
/// ألوان TETE — فضاء غامق هادي. ممنوع: بينك / موف فاتح / ألوان صارخة.
class C {
  static const bg = Color(0xFF0A0E1A);
  static const card = Color(0xFF141A2E);
  static const raised = Color(0xFF1C2340);
  static const border = Color(0xFF232B45);
  static const text = Color(0xFFE6EAF2);
  static const sub = Color(0xFF8A93A8);
  static const dim = Color(0xFF5A6278);
  static const accent = Color(0xFF6C8EFF);
  static const accent2 = Color(0xFF9B8CFF);
  static const ok = Color(0xFF4ADE80);
  static const warn = Color(0xFFF59E0B);
}

TextStyle mono({double size = 14, Color color = C.text, FontWeight w = FontWeight.w500}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, color: color, fontWeight: w);

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final tt = GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme)
      .apply(bodyColor: C.text, displayColor: C.text);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.accent,
      secondary: C.accent2,
      surface: C.card,
      onSurface: C.text,
    ),
    textTheme: tt,
    dividerColor: C.border,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.bg,
      indicatorColor: C.raised,
      height: 66,
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.ibmPlexSansArabic(fontSize: 11, color: C.sub),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.raised,
      hintStyle: const TextStyle(color: C.dim),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.accent,
        foregroundColor: C.bg,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: C.accent),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? C.accent : C.sub),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? C.raised : C.card),
    ),
  );
}


// ════════ models ════════
/// الستيكرات: 6 أساسية + 4 اختيارية. ستيكر واحد في اليوم (وبيتعدل في أي وقت).
const stickers = <(String, String)>[
  ('⭐', 'يوم مميز'),
  ('🪐', 'يوم هادي'),
  ('🌙', 'يوم راحة'),
  ('☄️', 'يوم سريع'),
  ('🌑', 'يوم صعب'),
  ('✨', 'يوم حلو'),
  ('🔭', 'استكشاف'),
  ('🌠', 'أمل'),
  ('🛸', 'غريب'),
  ('🌌', 'عميق'),
];

String stickerLabel(String? e) {
  for (final s in stickers) {
    if (s.$1 == e) return s.$2;
  }
  return '';
}

const energyLabels = ['خفيف', 'متوسط', 'تقيل'];

String uid() =>
    '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';

class Habit {
  String id, title, icon;
  int energy; // 0 خفيف / 1 متوسط / 2 تقيل

  Habit({required this.id, required this.title, this.icon = '•', this.energy = 1});

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'icon': icon, 'energy': energy};

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'],
        title: j['title'],
        icon: j['icon'] ?? '•',
        energy: j['energy'] ?? 1,
      );
}

class DailyTask {
  String id, title;
  bool done, big; // big = من "الـ 3 الكبار"
  int energy;

  DailyTask({
    required this.id,
    required this.title,
    this.done = false,
    this.big = false,
    this.energy = 1,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'done': done, 'big': big, 'energy': energy};

  factory DailyTask.fromJson(Map<String, dynamic> j) => DailyTask(
        id: j['id'],
        title: j['title'],
        done: j['done'] ?? false,
        big: j['big'] ?? false,
        energy: j['energy'] ?? 1,
      );
}

class DayData {
  Set<String> habitsDone;
  List<DailyTask> tasks;
  int cups;
  String? sticker;
  bool closed;
  String intention;
  bool? intentOk;
  String gratitude;

  DayData({
    Set<String>? habitsDone,
    List<DailyTask>? tasks,
    this.cups = 0,
    this.sticker,
    this.closed = false,
    this.intention = '',
    this.intentOk,
    this.gratitude = '',
  })  : habitsDone = habitsDone ?? {},
        tasks = tasks ?? [];

  Map<String, dynamic> toJson() => {
        'h': habitsDone.toList(),
        't': tasks.map((e) => e.toJson()).toList(),
        'c': cups,
        's': sticker,
        'x': closed,
        'i': intention,
        'ok': intentOk,
        'g': gratitude,
      };

  factory DayData.fromJson(Map<String, dynamic> j) => DayData(
        habitsDone: Set<String>.from(j['h'] ?? []),
        tasks: ((j['t'] ?? []) as List)
            .map((e) => DailyTask.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        cups: j['c'] ?? 0,
        sticker: j['s'],
        closed: j['x'] ?? false,
        intention: j['i'] ?? '',
        intentOk: j['ok'],
        gratitude: j['g'] ?? '',
      );
}

class Note {
  String id, date, content;
  bool pinned;

  Note({required this.id, required this.date, required this.content, this.pinned = false});

  Map<String, dynamic> toJson() =>
      {'id': id, 'date': date, 'content': content, 'pinned': pinned};

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'],
        date: j['date'],
        content: j['content'] ?? '',
        pinned: j['pinned'] ?? false,
      );
}


// ════════ quotes ════════
/// اقتباسات مبدئية. الشعر المختار من التراث (المتنبي، شوقي، إيليا أبو ماضي).
/// ضيفي لحد 120+ بنفس التوزيع: 40% نصايح / 25% فلسفة / 20% شعر / 10% فضاء / 5% همسات.
const generalQuotes = <String>[
  // نصايح عملية
  'اشربي مياه قبل القهوة، وابدئي يومك بحاجة صغيرة تعرفي تخلصيها.',
  'ابدأي بأسهل تاسك. الزخم بيتبني من أول خطوة مش من الخطة.',
  'نامي كويس النهاردة، دي أحسن استثمار لبكرة.',
  'تاسك واحد بتخلصيه أحسن من خمسة بتفكري فيهم.',
  'قومي وامشي خمس دقايق. دماغك هتشكرك.',
  'اكتبي اللي في دماغك على ورقة، وسيبيها تريّحك.',
  'قللي عدد اللي عايزة تعمليه، وزوّدي جودة اللي بتعمليه.',
  'الراحة جزء من الشغل، مش مكافأة بعده.',
  // فلسفة / علم
  'النجوم اللي بنشوفها بعضها مات من زمان — والضوء لسه بيوصلنا.',
  'مش لازم تكوني أحسن من إمبارح بكتير. يكفي إنك ما رجعتيش.',
  'القلق بيعيش في بكرة، وإنتِ عايشة في النهاردة.',
  'التقدم البطيء لسه تقدم.',
  'اللي بتزرعيه بهدوء، بيكبر من غير ضجة.',
  'مش كل يوم لازم يكون مثمر. بعض الأيام وظيفتها إنك تعدّي بسلام.',
  // شعر عربي (تراث)
  'على قدر أهل العزم تأتي العزائم — المتنبي',
  'وما نيل المطالب بالتمنّي ولكن تؤخذ الدنيا غلابا — أحمد شوقي',
  'كن جميلًا ترَ الوجود جميلًا — إيليا أبو ماضي',
  'ما كل ما يتمنى المرء يدركه، تجري الرياح بما لا تشتهي السفن — المتنبي',
  // فضاء
  'إنتِ غبار نجوم بيحلم.',
  'في السما مليارات المجرات، وفي يومك مكان لحاجة حلوة واحدة.',
  'القمر بيتغير كل ليلة، ومحدش بيقول إنه فاشل.',
  'الفضاء واسع، بس يومك ليه مدار تعرفيه.',
  // همسات
  'خطوة صغيرة كفاية.',
  'إنتِ أقرب مما تتخيلي.',
  'براحتك، إحنا مش في سباق.',
  'كفاية إنك هنا.',
];

/// اقتباسات داعمة لأيام 🌑 الصعبة.
const supportQuotes = <String>[
  'اليوم الصعب مش حكم عليكي. هو يوم وهيعدّي.',
  'خدي نفس عميق. مش لازم تنجزي كل حاجة النهاردة.',
  'لو خلصتي حاجة واحدة بس، فده كفاية جدًا.',
  'الأيام التقيلة بتعدّي، وإنتِ بتعدّي معاها.',
  'مش لازم تكوني قوية طول الوقت.',
  'اشربي مياه، وكلي حاجة حلوة، وسيبي الباقي لبكرة.',
  'حتى القمر بيعدّي بمرحلة معتمة وبيرجع.',
];

String pickQuote(List<String> custom, DateTime d, String? sticker, int shift) {
  final hard = sticker == '🌑';
  final pool = hard ? supportQuotes : [...generalQuotes, ...custom];
  final doy = d.difference(DateTime(d.year, 1, 1)).inDays;
  return pool[(doy * 7 + shift) % pool.length];
}


// ════════ store ════════
/// كل البيانات محلية 100% (SharedPreferences كـ JSON واحد).
/// لما التطبيق يكبر، ممكن تنقلي لـ SQLite/Drift من غير ما الشاشات تتغير.
class AppStore extends ChangeNotifier {
  static const _k = 'tete_v1';
  late SharedPreferences _p;

  List<Habit> habits = [];
  final Map<String, DayData> days = {};
  List<Note> notes = [];
  int waterGoal = 8;
  bool stars = true;
  List<String> customQuotes = [];

  static String key(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
  static DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

  // ───────── تحميل / حفظ ─────────
  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final raw = _p.getString(_k);
    if (raw == null) {
      _defaults();
    } else {
      try {
        _fromMap(Map<String, dynamic>.from(jsonDecode(raw)));
      } catch (_) {
        _defaults();
      }
    }
  }

  void _defaults() {
    habits = [
      Habit(id: uid(), title: 'أذكار', icon: '🤲', energy: 0),
      Habit(id: uid(), title: 'تمدد وتنفس', icon: '🧘', energy: 0),
      Habit(id: uid(), title: 'قراءة', icon: '📖', energy: 1),
      Habit(id: uid(), title: 'مشي', icon: '🚶', energy: 2),
    ];
  }

  void _fromMap(Map<String, dynamic> m) {
    habits = ((m['habits'] ?? []) as List)
        .map((e) => Habit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    days.clear();
    ((m['days'] ?? {}) as Map).forEach((k, v) {
      days[k as String] = DayData.fromJson(Map<String, dynamic>.from(v));
    });
    notes = ((m['notes'] ?? []) as List)
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    waterGoal = m['water'] ?? 8;
    stars = m['stars'] ?? true;
    customQuotes = List<String>.from(m['quotes'] ?? []);
  }

  Map<String, dynamic> _toMap() => {
        'habits': habits.map((e) => e.toJson()).toList(),
        'days': days.map((k, v) => MapEntry(k, v.toJson())),
        'notes': notes.map((e) => e.toJson()).toList(),
        'water': waterGoal,
        'stars': stars,
        'quotes': customQuotes,
      };

  /// احفظي + حدّثي الشاشات.
  void commit() {
    _p.setString(_k, jsonEncode(_toMap()));
    notifyListeners();
  }

  String exportJson() => jsonEncode(_toMap());

  bool importJson(String raw) {
    try {
      _fromMap(Map<String, dynamic>.from(jsonDecode(raw)));
      commit();
      return true;
    } catch (_) {
      return false;
    }
  }

  void wipe() {
    days.clear();
    notes = [];
    customQuotes = [];
    waterGoal = 8;
    _defaults();
    commit();
  }

  // ───────── الأيام ─────────
  DayData day(DateTime d) => days.putIfAbsent(key(d), () => DayData());
  DayData? peek(DateTime d) => days[key(d)];

  double progress(DateTime d) {
    final x = days[key(d)];
    if (x == null) return 0;
    final ids = habits.map((h) => h.id).toSet();
    final total = habits.length + x.tasks.length;
    if (total == 0) return 0;
    final done = x.habitsDone.where(ids.contains).length +
        x.tasks.where((t) => t.done).length;
    return done / total;
  }

  // ───────── العادات ─────────
  void toggleHabit(DateTime d, String id) {
    final x = day(d);
    x.habitsDone.contains(id) ? x.habitsDone.remove(id) : x.habitsDone.add(id);
    commit();
  }

  bool habitDone(DateTime d, String id) => days[key(d)]?.habitsDone.contains(id) ?? false;

  /// أيام متواصلة (لو النهاردة لسه ما اتعلّمتش، بيبدأ العد من إمبارح).
  int streak(String id) {
    var d = DateTime.now();
    if (!habitDone(d, id)) d = addDays(d, -1);
    var s = 0;
    while (habitDone(d, id)) {
      s++;
      d = addDays(d, -1);
    }
    return s;
  }

  /// صياغة ألطف من السلسلة اللي بتتكسر: كام يوم من آخر 7.
  int last7(String id) {
    var c = 0;
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      if (habitDone(addDays(now, -i), id)) c++;
    }
    return c;
  }

  void addHabit(String title, String icon, int energy) {
    habits.add(Habit(id: uid(), title: title, icon: icon.isEmpty ? '•' : icon, energy: energy));
    commit();
  }

  void removeHabit(String id) {
    habits.removeWhere((h) => h.id == id);
    commit();
  }

  void setHabitEnergy(String id, int e) {
    habits.firstWhere((h) => h.id == id).energy = e;
    commit();
  }

  // ───────── تاسكات اليوم ─────────
  void addTask(DateTime d, String title, int energy) {
    day(d).tasks.add(DailyTask(id: uid(), title: title, energy: energy));
    commit();
  }

  void toggleTask(DateTime d, String id) {
    final t = day(d).tasks.firstWhere((e) => e.id == id);
    t.done = !t.done;
    commit();
  }

  void toggleBig(DateTime d, String id) {
    final x = day(d);
    final t = x.tasks.firstWhere((e) => e.id == id);
    if (!t.big && x.tasks.where((e) => e.big).length >= 3) return; // 3 بس
    t.big = !t.big;
    commit();
  }

  void deleteTask(DateTime d, String id) {
    day(d).tasks.removeWhere((e) => e.id == id);
    commit();
  }

  // ───────── مياه / ستيكر / نية / إقفال ─────────
  void setCups(DateTime d, int n) {
    day(d).cups = n.clamp(0, 30);
    commit();
  }

  void setSticker(DateTime d, String? s) {
    day(d).sticker = s;
    commit();
  }

  void setIntention(DateTime d, String t) {
    day(d).intention = t.trim();
    commit();
  }

  void setIntentOk(DateTime d, bool? v) {
    day(d).intentOk = v;
    commit();
  }

  void closeDay(DateTime d, String? sticker, String gratitude) {
    final x = day(d);
    x.closed = true;
    if (sticker != null) x.sticker = sticker;
    x.gratitude = gratitude.trim();
    commit();
  }

  void reopenDay(DateTime d) {
    day(d).closed = false;
    commit();
  }

  // ───────── النوتات ─────────
  void saveNote(Note n) {
    final i = notes.indexWhere((e) => e.id == n.id);
    if (i >= 0) {
      notes[i] = n;
    } else {
      notes.add(n);
    }
    commit();
  }

  void deleteNote(String id) {
    notes.removeWhere((e) => e.id == id);
    commit();
  }

  // ───────── إعدادات ─────────
  void setWaterGoal(int g) {
    waterGoal = g.clamp(1, 20);
    commit();
  }

  void setStars(bool v) {
    stars = v;
    commit();
  }

  void addQuote(String q) {
    customQuotes.add(q.trim());
    commit();
  }

  void removeQuote(int i) {
    customQuotes.removeAt(i);
    commit();
  }
}


// ════════ starfield ════════
class _Star {
  final double x, y, r, phase, speed;
  _Star(this.x, this.y, this.r, this.phase, this.speed);
}

/// نجوم ناعمة بتتحرك ببطء جدًا (دورة 60 ثانية).
class Starfield extends StatefulWidget {
  const Starfield({super.key});
  @override
  State<Starfield> createState() => _StarfieldState();
}

class _StarfieldState extends State<Starfield> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();

  final List<_Star> _stars = List.generate(80, (i) {
    final r = Random(i * 7 + 3);
    return _Star(r.nextDouble(), r.nextDouble(), r.nextDouble() * 1.2 + 0.3,
        r.nextDouble() * 6.28, r.nextDouble() * 0.6 + 0.2);
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _StarPainter(_stars, _c.value),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in stars) {
      final x = ((s.x + t * s.speed * 0.15) % 1.0) * size.width;
      final y = s.y * size.height;
      final tw = 0.5 + 0.5 * sin(t * 2 * pi * 6 + s.phase);
      p.color = C.text.withOpacity(0.08 + 0.35 * tw * (s.r / 1.5));
      canvas.drawCircle(Offset(x, y), s.r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter old) => old.t != t;
}


// ════════ widgets ════════
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: C.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border),
      ),
      child: child,
    );
    return onTap == null ? box : GestureDetector(onTap: onTap, child: box);
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: C.sub)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

/// شيك بوكس دائري ناعم (300ms max) مع هابتيك.
class CircleCheck extends StatelessWidget {
  final bool done;
  final VoidCallback onTap;
  final double size;
  const CircleCheck({super.key, required this.done, required this.onTap, this.size = 26});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? C.accent : Colors.transparent,
              border: Border.all(color: done ? C.accent : C.dim, width: 1.6),
            ),
            child: done ? Icon(Icons.check, size: size * 0.62, color: C.bg) : null,
          ),
        ),
      );
}

Future<void> pickSticker(BuildContext context, DateTime date) {
  final s = context.read<AppStore>();
  return showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إيه إحساس اليوم؟',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('ممكن تغيّريه في أي وقت لحد آخر اليوم.',
              style: TextStyle(color: C.sub, fontSize: 13)),
          const SizedBox(height: 16),
          StickerWrap(
            selected: s.peek(date)?.sticker,
            onPick: (e) {
              s.setSticker(date, e);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

class StickerWrap extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onPick;
  const StickerWrap({super.key, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final st in stickers)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onPick(st.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 92,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == st.$1 ? C.raised : C.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: selected == st.$1 ? C.accent : C.border),
                ),
                child: Column(
                  children: [
                    Text(st.$1, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(st.$2,
                        style: const TextStyle(fontSize: 11, color: C.sub)),
                  ],
                ),
              ),
            ),
        ],
      );
}

/// Chips لاختيار مستوى الطاقة.
class EnergyPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const EnergyPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < 3; i++)
            ChoiceChip(
              label: Text(energyLabels[i], style: const TextStyle(fontSize: 12)),
              selected: value == i,
              onSelected: (_) => onChanged(i),
              selectedColor: C.raised,
              backgroundColor: C.bg,
              side: BorderSide(color: value == i ? C.accent : C.border),
              showCheckmark: false,
              labelStyle: TextStyle(color: value == i ? C.text : C.sub),
            ),
        ],
      );
}


// ════════ screens/today ════════
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _showAll = false;
  int _shift = 0;
  int _energy = 1;
  final _task = TextEditingController();
  final _intent = TextEditingController();

  @override
  void initState() {
    super.initState();
    _intent.text = context.read<AppStore>().day(DateTime.now()).intention;
  }

  @override
  void dispose() {
    _task.dispose();
    _intent.dispose();
    super.dispose();
  }

  String _greet(int h) {
    if (h < 5) return 'وقت الهدوء 🌙';
    if (h < 12) return 'صباح الخير ☀️';
    if (h < 17) return 'نهارك هادي 🪐';
    if (h < 21) return 'مساء الخير ✨';
    return 'وقت الهدوء 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final now = DateTime.now();
    final d = s.day(now);
    final hard = d.sticker == '🌑';
    final easy = hard && !_showAll;
    final habits = s.habits.where((h) => !easy || h.energy == 0).toList();
    final tasks = d.tasks.where((t) => !easy || t.energy == 0).toList()
      ..sort((a, b) => (b.big ? 1 : 0).compareTo(a.big ? 1 : 0));
    final prog = s.progress(now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // ① هيدر
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greet(now.hour),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(DateFormat('EEEE d MMMM', 'ar').format(now),
                        style: const TextStyle(color: C.sub, fontSize: 14)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => pickSticker(context, now),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.border),
                  ),
                  child: Text(d.sticker ?? '＋', style: const TextStyle(fontSize: 24)),
                ),
              ),
            ],
          ),
        ),

        // ② الاقتباس
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pickQuote(s.customQuotes, now, d.sticker, _shift),
                  style: const TextStyle(fontSize: 16, height: 1.7)),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: GestureDetector(
                  onTap: () => setState(() => _shift++),
                  child: const Text('اقتباس آخر ✨',
                      style: TextStyle(color: C.accent, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),

        // ③ نية اليوم
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('نية اليوم'),
              TextField(
                controller: _intent,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(hintText: 'النهاردة هركّز على…'),
                onSubmitted: (v) => s.setIntention(now, v),
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                  if (_intent.text.trim() != d.intention) s.setIntention(now, _intent.text);
                },
              ),
              if (d.intention.isNotEmpty && now.hour >= 18) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text('اتحققت؟', style: TextStyle(color: C.sub)),
                    ),
                    for (final v in [true, false])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: ChoiceChip(
                          label: Text(v ? 'أيوه' : 'مش أوي'),
                          selected: d.intentOk == v,
                          onSelected: (_) => s.setIntentOk(now, v),
                          selectedColor: C.raised,
                          backgroundColor: C.bg,
                          side: BorderSide(color: d.intentOk == v ? C.accent : C.border),
                          showCheckmark: false,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // يوم صعب → الخفيف بس
        if (hard)
          Panel(
            child: Row(
              children: [
                const Text('🌑', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    easy ? 'يوم صعب؟ هنعرض الخفيف بس.' : 'بتعرضي كل حاجة.',
                    style: const TextStyle(color: C.sub, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(easy ? 'اعرضي الكل' : 'الخفيف بس'),
                ),
              ],
            ),
          ),

        // ④ كل يوم
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('كل يوم'),
              if (habits.isEmpty)
                const Text('ضيفي عادات من الإعدادات.', style: TextStyle(color: C.dim)),
              for (final h in habits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleCheck(
                        done: s.habitDone(now, h.id),
                        onTap: () => s.toggleHabit(now, h.id),
                      ),
                      const SizedBox(width: 10),
                      Text(h.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(h.title, style: const TextStyle(fontSize: 15))),
                      if (s.streak(h.id) >= 3)
                        Text('🔥${s.streak(h.id)} ', style: mono(size: 12, color: C.warn)),
                      Text('${s.last7(h.id)}/7', style: mono(size: 12, color: C.dim)),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // ⑤ النهاردة بس
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('النهاردة بس'),
              for (final t in tasks)
                Dismissible(
                  key: ValueKey(t.id),
                  onDismissed: (_) => s.deleteTask(now, t.id),
                  background: Container(color: C.raised),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleCheck(done: t.done, onTap: () => s.toggleTask(now, t.id)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 15,
                              color: t.done ? C.dim : C.text,
                              decoration: t.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            s.toggleBig(now, t.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              t.big ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 20,
                              color: t.big ? C.accent2 : C.dim,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (tasks.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: Text('⭐ علّمي لحد 3 تاسكات كبار • اسحبي للحذف',
                      style: TextStyle(color: C.dim, fontSize: 11)),
                ),
              TextField(
                controller: _task,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '+ إضافة تاسك',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded, color: C.accent),
                    onPressed: _addTask,
                  ),
                ),
                onSubmitted: (_) => _addTask(),
              ),
              const SizedBox(height: 10),
              EnergyPicker(value: _energy, onChanged: (v) => setState(() => _energy = v)),
            ],
          ),
        ),

        // ⑥ المياه
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(
                '💧 المياه',
                trailing: Text('${d.cups}/${s.waterGoal}', style: mono(size: 14, color: C.accent)),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < s.waterGoal; i++)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        s.setCups(now, d.cups == i + 1 ? i : i + 1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < d.cups ? C.accent.withOpacity(0.85) : Colors.transparent,
                          border: Border.all(color: i < d.cups ? C.accent : C.dim, width: 1.4),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        s.setCups(now, d.cups + 1);
                      },
                      child: const Text('+ كوباية'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: d.cups > 0 ? () => s.setCups(now, d.cups - 1) : null,
                    icon: const Icon(Icons.remove_rounded),
                    color: C.sub,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ⑦ إقفال اليوم
        if (d.closed)
          Panel(
            child: Column(
              children: [
                const Text('اليوم اتقفل ✅', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                if (d.gratitude.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('شكرًا لنفسي: ${d.gratitude}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: C.sub, height: 1.6)),
                ],
                TextButton(
                  onPressed: () => s.reopenDay(now),
                  child: const Text('فتح اليوم تاني'),
                ),
              ],
            ),
          )
        else if (prog >= 0.5)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton(
              onPressed: () => _closeSheet(context, now),
              child: const Text('إقفال اليوم 🌌'),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Center(
              child: Text('لما تخلصي نص يومك، هيظهر زرار إقفال اليوم.',
                  style: TextStyle(color: C.dim, fontSize: 12)),
            ),
          ),

        // ⑧ همسة
        const SizedBox(height: 8),
        const Center(
          child: Text('إنتِ أقرب مما تتخيلي',
              style: TextStyle(color: C.dim, fontSize: 13)),
        ),
      ],
    );
  }

  void _addTask() {
    final t = _task.text.trim();
    if (t.isEmpty) return;
    context.read<AppStore>().addTask(DateTime.now(), t, _energy);
    _task.clear();
  }

  void _closeSheet(BuildContext context, DateTime now) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CloseSheet(date: now),
    );
  }
}

class _CloseSheet extends StatefulWidget {
  final DateTime date;
  const _CloseSheet({required this.date});
  @override
  State<_CloseSheet> createState() => _CloseSheetState();
}

class _CloseSheetState extends State<_CloseSheet> {
  final _g = TextEditingController();
  String? _sticker;

  @override
  void initState() {
    super.initState();
    _sticker = context.read<AppStore>().peek(widget.date)?.sticker;
  }

  @override
  void dispose() {
    _g.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppStore>();
    final d = s.day(widget.date);
    final pct = (s.progress(widget.date) * 100).round();
    final done = d.tasks.where((t) => t.done).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('إقفال اليوم', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat('$pct%', 'إنجاز'),
                _stat('$done', 'تاسك'),
                _stat('${d.cups}', 'كوباية'),
              ],
            ),
            const SizedBox(height: 18),
            const Text('إحساس اليوم', style: TextStyle(color: C.sub)),
            const SizedBox(height: 10),
            StickerWrap(selected: _sticker, onPick: (e) => setState(() => _sticker = e)),
            const SizedBox(height: 18),
            TextField(
              controller: _g,
              decoration: const InputDecoration(hintText: 'شكرًا لنفسي على… (اختياري)'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  s.closeDay(widget.date, _sticker, _g.text);
                  Navigator.pop(context);
                },
                child: const Text('تمام، اقفلي اليوم ✅'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String v, String l) => Expanded(
        child: Column(
          children: [
            Text(v, style: mono(size: 22, color: C.accent)),
            const SizedBox(height: 2),
            Text(l, style: const TextStyle(color: C.sub, fontSize: 12)),
          ],
        ),
      );
}


// ════════ screens/calendar ════════
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _m = DateTime(DateTime.now().year, DateTime.now().month);

  void _go(int n) => setState(() => _m = DateTime(_m.year, _m.month + n));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final count = DateUtils.getDaysInMonth(_m.year, _m.month);
    final offset = (_m.weekday + 1) % 7; // السبت أول يوم
    final today = DateTime.now();

    // نقاط الكوكبة
    final pts = <_SkyPt>[];
    for (var i = 1; i <= count; i++) {
      final dt = DateTime(_m.year, _m.month, i);
      final day = s.peek(dt);
      final rnd = Random(_m.year * 1000 + _m.month * 40 + i);
      pts.add(_SkyPt(
        x: (i - 0.5) / count,
        y: 0.18 + rnd.nextDouble() * 0.64,
        closed: day?.closed ?? false,
        progress: s.progress(dt),
      ));
    }
    final closedCount = pts.where((p) => p.closed).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            IconButton(onPressed: () => _go(1), icon: const Icon(Icons.chevron_right_rounded)),
            Expanded(
              child: Center(
                child: Text(DateFormat('MMMM yyyy', 'ar').format(_m),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ),
            IconButton(onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left_rounded)),
          ],
        ),
        const SizedBox(height: 8),

        // سماء الشهر
        Panel(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CustomPaint(painter: _SkyPainter(pts)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  closedCount == 0
                      ? 'كل يوم تقفليه = نجمة. آخر الشهر هتتكوّن كوكبتك 🌌'
                      : '$closedCount نجمة في سماء الشهر',
                  style: const TextStyle(color: C.sub, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // الأسبوع
        Row(
          children: [
            for (final w in ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'])
              Expanded(
                child: Center(
                  child: Text(w, style: const TextStyle(color: C.dim, fontSize: 12)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (var i = 0; i < offset; i++) const SizedBox(),
            for (var i = 1; i <= count; i++) _cell(context, s, DateTime(_m.year, _m.month, i), today),
          ],
        ),
      ],
    );
  }

  Widget _cell(BuildContext context, AppStore s, DateTime dt, DateTime today) {
    final day = s.peek(dt);
    final isToday = DateUtils.isSameDay(dt, today);
    final prog = s.progress(dt);
    final hasNote = s.notes.any((n) => n.date == AppStore.key(dt));
    return GestureDetector(
      onTap: () => showDaySheet(context, dt),
      child: Container(
        decoration: BoxDecoration(
          color: C.accent.withOpacity(0.05 + 0.25 * prog),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isToday ? C.accent : C.border),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${dt.day}', style: mono(size: 12, color: C.sub)),
                  Text(day?.sticker ?? (day?.closed == true ? '✅' : ''),
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            if (hasNote)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(color: C.accent2, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SkyPt {
  final double x, y, progress;
  final bool closed;
  _SkyPt({required this.x, required this.y, required this.closed, required this.progress});
}

class _SkyPainter extends CustomPainter {
  final List<_SkyPt> pts;
  _SkyPainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = C.bg.withOpacity(0.6));
    Offset pos(_SkyPt p) => Offset(p.x * size.width, p.y * size.height);

    final dot = Paint()..color = C.dim.withOpacity(0.5);
    for (final p in pts.where((p) => !p.closed)) {
      canvas.drawCircle(pos(p), 1.1, dot);
    }

    final closed = pts.where((p) => p.closed).toList();
    final line = Paint()
      ..color = C.accent.withOpacity(0.35)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < closed.length - 1; i++) {
      canvas.drawLine(pos(closed[i]), pos(closed[i + 1]), line);
    }

    final glow = Paint()
      ..color = C.accent2.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final star = Paint()..color = C.text;
    for (final p in closed) {
      final r = 2.2 + 2.6 * p.progress;
      canvas.drawCircle(pos(p), r * 2, glow);
      canvas.drawCircle(pos(p), r, star);
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => true;
}

/// صفحة اليوم الكاملة.
void showDaySheet(BuildContext context, DateTime dt) {
  final s = context.read<AppStore>();
  final day = s.peek(dt);
  final notes = s.notes.where((n) => n.date == AppStore.key(dt)).toList();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(DateFormat('EEEE d MMMM', 'ar').format(dt),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              Text(day?.sticker ?? '', style: const TextStyle(fontSize: 28)),
            ],
          ),
          if (day == null)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('اليوم ده فاضي.', style: TextStyle(color: C.dim)),
            )
          else ...[
            const SizedBox(height: 4),
            Text(
              [
                if (day.sticker != null) stickerLabel(day.sticker),
                if (day.closed) 'مقفول ✅',
              ].join(' • '),
              style: const TextStyle(color: C.sub, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('${(s.progress(dt) * 100).round()}%', 'إنجاز'),
                _stat('${day.tasks.where((t) => t.done).length}', 'تاسك'),
                _stat('${day.cups}', 'كوباية'),
              ],
            ),
            if (day.intention.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('النية', style: TextStyle(color: C.sub, fontSize: 12)),
              const SizedBox(height: 4),
              Text(day.intention +
                  (day.intentOk == true ? '  ✓' : day.intentOk == false ? '  ✗' : '')),
            ],
            if (day.tasks.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('التاسكات', style: TextStyle(color: C.sub, fontSize: 12)),
              const SizedBox(height: 6),
              for (final t in day.tasks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${t.done ? '✓' : '○'}  ${t.title}',
                      style: TextStyle(color: t.done ? C.text : C.dim)),
                ),
            ],
            if (day.gratitude.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text('شكرًا لنفسي', style: TextStyle(color: C.sub, fontSize: 12)),
              const SizedBox(height: 4),
              Text(day.gratitude),
            ],
          ],
          for (final n in notes) ...[
            const SizedBox(height: 18),
            const Text('نوتة', style: TextStyle(color: C.sub, fontSize: 12)),
            const SizedBox(height: 4),
            Text(n.content, style: const TextStyle(height: 1.6)),
          ],
        ],
      ),
    ),
  );
}

Widget _stat(String v, String l) => Expanded(
      child: Column(
        children: [
          Text(v, style: mono(size: 20, color: C.accent)),
          const SizedBox(height: 2),
          Text(l, style: const TextStyle(color: C.sub, fontSize: 12)),
        ],
      ),
    );


// ════════ screens/notes ════════
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final list = s.notes
        .where((n) => _q.isEmpty || n.content.contains(_q))
        .toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.date.compareTo(a.date);
      });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('نوتات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              IconButton.filled(
                onPressed: () => _edit(context, null),
                style: IconButton.styleFrom(backgroundColor: C.accent, foregroundColor: C.bg),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _q = v.trim()),
            decoration: const InputDecoration(
              hintText: 'بحث…',
              prefixIcon: Icon(Icons.search_rounded, color: C.dim),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('مفيش نوتات لسه ✨', style: TextStyle(color: C.dim)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final n = list[i];
                      return Dismissible(
                        key: ValueKey(n.id),
                        onDismissed: (_) => s.deleteNote(n.id),
                        background: Container(color: C.raised),
                        child: Panel(
                          onTap: () => _edit(context, n),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (n.pinned)
                                    const Padding(
                                      padding: EdgeInsetsDirectional.only(end: 6),
                                      child: Icon(Icons.push_pin_rounded, size: 14, color: C.accent2),
                                    ),
                                  Text(
                                    DateFormat('d MMMM', 'ar').format(DateTime.parse(n.date)),
                                    style: const TextStyle(color: C.sub, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(n.content,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(height: 1.6)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context, Note? n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NoteEditor(note: n),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  final Note? note;
  const _NoteEditor({this.note});
  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final _c = TextEditingController(text: widget.note?.content ?? '');
  late bool _pin = widget.note?.pinned ?? false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppStore>();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('نوتة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                onPressed: () => setState(() => _pin = !_pin),
                icon: Icon(_pin ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    color: _pin ? C.accent2 : C.dim),
              ),
            ],
          ),
          TextField(
            controller: _c,
            autofocus: true,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(hintText: 'اكتبي براحتك…'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final t = _c.text.trim();
                if (t.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                s.saveNote(Note(
                  id: widget.note?.id ?? uid(),
                  date: widget.note?.date ?? AppStore.key(DateTime.now()),
                  content: t,
                  pinned: _pin,
                ));
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ),
        ],
      ),
    );
  }
}


// ════════ screens/insights ════════
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final now = DateTime.now();
    final week = [for (var i = 6; i >= 0; i--) AppStore.addDays(now, -i)];

    final progs = [for (final d in week) s.progress(d)];
    final avgProg = progs.fold<double>(0, (a, b) => a + b) / 7;
    final cups = [for (final d in week) s.peek(d)?.cups ?? 0];
    final avgCups = cups.fold<int>(0, (a, b) => a + b) / 7;

    // أكتر يوم إنتاجية
    var bestI = 0;
    for (var i = 1; i < 7; i++) {
      if (progs[i] > progs[bestI]) bestI = i;
    }

    // أكتر ستيكر في آخر 30 يوم
    final freq = <String, int>{};
    for (var i = 0; i < 30; i++) {
      final st = s.peek(AppStore.addDays(now, -i))?.sticker;
      if (st != null) freq[st] = (freq[st] ?? 0) + 1;
    }
    String? topSticker;
    if (freq.isNotEmpty) {
      topSticker = freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    // الشهر الحالي
    final monthDays = DateUtils.getDaysInMonth(now.year, now.month);
    var closed = 0, tasksDone = 0, monthCups = 0;
    for (var i = 1; i <= monthDays; i++) {
      final x = s.peek(DateTime(now.year, now.month, i));
      if (x == null) continue;
      if (x.closed) closed++;
      tasksDone += x.tasks.where((t) => t.done).length;
      monthCups += x.cups;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text('إحصائيات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ),

        // الأسبوع
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('آخر 7 أيام',
                  trailing: Text('${(avgProg * 100).round()}%',
                      style: mono(size: 16, color: C.accent))),
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 16,
                              height: 6 + 70 * progs[i],
                              decoration: BoxDecoration(
                                color: i == bestI && progs[i] > 0
                                    ? C.accent2
                                    : C.accent.withOpacity(0.35 + 0.5 * progs[i]),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(DateFormat('E', 'ar').format(week[i]),
                                style: const TextStyle(color: C.dim, fontSize: 10)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _stat(avgCups.toStringAsFixed(1), 'متوسط المياه'),
                  _stat(progs.every((p) => p == 0) ? '—' : DateFormat('EEEE', 'ar').format(week[bestI]),
                      'أنشط يوم'),
                  _stat(topSticker ?? '—', 'أكتر إحساس'),
                ],
              ),
            ],
          ),
        ),

        // العادات
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('العادات'),
              if (s.habits.isEmpty) const Text('مفيش عادات.', style: TextStyle(color: C.dim)),
              for (final h in s.habits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Text(h.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(h.title)),
                      Text('${s.last7(h.id)} من 7', style: mono(size: 12, color: C.accent)),
                      const SizedBox(width: 10),
                      Text(s.streak(h.id) > 0 ? '🔥${s.streak(h.id)}' : '',
                          style: mono(size: 12, color: C.warn)),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              Text(_cheer(avgProg),
                  style: const TextStyle(color: C.sub, fontSize: 13, height: 1.6)),
            ],
          ),
        ),

        // الشهر
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(DateFormat('MMMM', 'ar').format(now)),
              Row(
                children: [
                  _stat('$closed', 'يوم مقفول'),
                  _stat('$tasksDone', 'تاسك'),
                  _stat('$monthCups', 'كوباية'),
                ],
              ),
              const SizedBox(height: 12),
              const Text('كوكبة الشهر موجودة في تاب "الشهر" 🪐',
                  style: TextStyle(color: C.dim, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  String _cheer(double p) {
    if (p == 0) return 'أسبوع جديد، وبدايته لما تحبي.';
    if (p < 0.4) return 'خطوات صغيرة بتبني حاجة كبيرة.';
    if (p < 0.75) return 'ماشية كويس. الثبات أهم من الكمال.';
    return 'أسبوع هادي وقوي. خدي لحظة فخر ✨';
  }

  Widget _stat(String v, String l) => Expanded(
        child: Column(
          children: [
            Text(v,
                textAlign: TextAlign.center,
                style: mono(size: v.length > 4 ? 13 : 20, color: C.accent)),
            const SizedBox(height: 4),
            Text(l, style: const TextStyle(color: C.sub, fontSize: 11)),
          ],
        ),
      );
}


// ════════ screens/settings ════════
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text('إعدادات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        ),

        // العادات
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('عاداتي اليومية',
                  trailing: IconButton(
                    onPressed: () => _addHabit(context),
                    icon: const Icon(Icons.add_rounded, color: C.accent),
                  )),
              for (final h in s.habits)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(h.icon, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(h.title)),
                      GestureDetector(
                        onTap: () => s.setHabitEnergy(h.id, (h.energy + 1) % 3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: C.raised,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(energyLabels[h.energy],
                              style: const TextStyle(color: C.sub, fontSize: 11)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => s.removeHabit(h.id),
                        icon: const Icon(Icons.close_rounded, size: 18, color: C.dim),
                      ),
                    ],
                  ),
                ),
              const Text('اضغطي على مستوى الطاقة عشان تغيّريه.',
                  style: TextStyle(color: C.dim, fontSize: 11)),
            ],
          ),
        ),

        // المياه
        Panel(
          child: Row(
            children: [
              const Expanded(child: Text('هدف المياه (كوبايات)')),
              IconButton(
                onPressed: () => s.setWaterGoal(s.waterGoal - 1),
                icon: const Icon(Icons.remove_rounded),
              ),
              Text('${s.waterGoal}', style: mono(size: 18, color: C.accent)),
              IconButton(
                onPressed: () => s.setWaterGoal(s.waterGoal + 1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),

        // المظهر
        Panel(
          child: Row(
            children: [
              const Expanded(child: Text('نجوم الخلفية ✨')),
              Switch(value: s.stars, onChanged: s.setStars),
            ],
          ),
        ),

        // اقتباساتي
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('اقتباساتي',
                  trailing: IconButton(
                    onPressed: () => _addQuote(context),
                    icon: const Icon(Icons.add_rounded, color: C.accent),
                  )),
              if (s.customQuotes.isEmpty)
                const Text('ضيفي جمل بتحبيها، وهتظهر في الدوران اليومي.',
                    style: TextStyle(color: C.dim, fontSize: 13)),
              for (var i = 0; i < s.customQuotes.length; i++)
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(s.customQuotes[i], style: const TextStyle(height: 1.5)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => s.removeQuote(i),
                      icon: const Icon(Icons.close_rounded, size: 18, color: C.dim),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // البيانات
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('بياناتي (محلية 100%)'),
              _row(Icons.copy_rounded, 'نسخ نسخة احتياطية (JSON)', () async {
                await Clipboard.setData(ClipboardData(text: s.exportJson()));
                if (context.mounted) _toast(context, 'اتنسخت. الصقيها في ملاحظات أو رسالة لنفسك.');
              }),
              _row(Icons.paste_rounded, 'استيراد نسخة احتياطية', () => _import(context)),
              _row(Icons.delete_outline_rounded, 'حذف كل حاجة', () => _wipe(context),
                  color: C.warn),
            ],
          ),
        ),

        const SizedBox(height: 8),
        const Center(
          child: Text('TETE 1.0 🌌', style: TextStyle(color: C.dim, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _row(IconData i, String t, VoidCallback f, {Color color = C.text}) => InkWell(
        onTap: f,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(i, size: 20, color: color == C.text ? C.sub : color),
              const SizedBox(width: 12),
              Text(t, style: TextStyle(color: color)),
            ],
          ),
        ),
      );

  void _toast(BuildContext c, String m) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m), backgroundColor: C.raised));

  void _addHabit(BuildContext context) {
    final t = TextEditingController();
    final ic = TextEditingController();
    var energy = 1;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('عادة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: t, decoration: const InputDecoration(hintText: 'الاسم')),
              const SizedBox(height: 10),
              TextField(controller: ic, decoration: const InputDecoration(hintText: 'إيموجي (اختياري)')),
              const SizedBox(height: 12),
              EnergyPicker(value: energy, onChanged: (v) => set(() => energy = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                if (t.text.trim().isNotEmpty) {
                  context.read<AppStore>().addHabit(t.text.trim(), ic.text.trim(), energy);
                }
                Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _addQuote(BuildContext context) {
    final t = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اقتباس جديد'),
        content: TextField(controller: t, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتبيه هنا')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              if (t.text.trim().isNotEmpty) context.read<AppStore>().addQuote(t.text);
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _import(BuildContext context) {
    final t = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استيراد'),
        content: TextField(controller: t, maxLines: 6, decoration: const InputDecoration(hintText: 'الصقي الـ JSON هنا')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              final ok = context.read<AppStore>().importJson(t.text.trim());
              Navigator.pop(ctx);
              _toast(context, ok ? 'اتستورد بنجاح ✅' : 'الملف مش صالح.');
            },
            child: const Text('استيراد'),
          ),
        ],
      ),
    );
  }

  void _wipe(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف كل حاجة؟'),
        content: const Text('كل الأيام والنوتات والعادات هتتمسح ومينفعش ترجعي فيها.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لأ')),
          TextButton(
            onPressed: () {
              context.read<AppStore>().wipe();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: C.warn),
            child: const Text('احذفي'),
          ),
        ],
      ),
    );
  }
}


// ════════ main ════════
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  final store = AppStore();
  await store.load();
  runApp(ChangeNotifierProvider.value(value: store, child: const TeteApp()));
}

class TeteApp extends StatelessWidget {
  const TeteApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TETE',
        theme: buildTheme(),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final stars = context.select<AppStore, bool>((s) => s.stars);
    return Scaffold(
      body: Stack(
        children: [
          if (stars) const Positioned.fill(child: Starfield()),
          SafeArea(
            child: IndexedStack(
              index: _i,
              children: const [
                TodayScreen(),
                CalendarScreen(),
                NotesScreen(),
                InsightsScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: C.border)),
        ),
        child: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (i) => setState(() => _i = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(icon: Text('🌑', style: TextStyle(fontSize: 20)), label: 'النهاردة'),
            NavigationDestination(icon: Text('🪐', style: TextStyle(fontSize: 20)), label: 'الشهر'),
            NavigationDestination(icon: Text('✨', style: TextStyle(fontSize: 20)), label: 'نوتات'),
            NavigationDestination(icon: Text('⭐', style: TextStyle(fontSize: 20)), label: 'إحصائيات'),
            NavigationDestination(icon: Text('☄️', style: TextStyle(fontSize: 20)), label: 'إعدادات'),
          ],
        ),
      ),
    );
  }
}