import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/leaf_background.dart';

/// =====================
/// 🌿 ЭКРАН ВИКТОРИНЫ
/// =====================
class QuizScreen extends StatefulWidget {
  final String quizId;
  final String title;
  final List<Map<String, dynamic>> questions;
  final int rewardPoints;

  const QuizScreen({
    super.key,
    required this.quizId,
    required this.title,
    required this.questions,
    this.rewardPoints = 50,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  List<int?> _answers = [];
  bool _saving = false;
  bool _showLeaf = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(widget.questions.length, null);
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _select(int optionIndex) {
    setState(() {
      _answers[_index] = optionIndex;
    });
  }

  void _next() {
    if (_index < widget.questions.length - 1) {
      setState(() {
        _animController.reverse().then((_) {
          _index++;
          _animController.forward();
        });
      });
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() {
        _animController.reverse().then((_) {
          _index--;
          _animController.forward();
        });
      });
    }
  }

  Future<void> _finish() async {
    final total = widget.questions.length;
    int correct = 0;
    for (int i = 0; i < total; i++) {
      if (_answers[i] == widget.questions[i]['answer']) correct++;
    }
    final percent = (correct / total) * 100.0;

    final userProv = Provider.of<UserProvider>(context, listen: false);
    final uid = userProv.firebaseUser?.uid ?? userProv.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);

    // 💾 Сохраняем результат
    final histRef =
    FirebaseDatabase.instance.ref('users/$uid/quizHistory/${widget.quizId}').push();
    await histRef.set({
      'timestamp': DateTime.now().toIso8601String(),
      'correct': correct,
      'total': total,
      'percent': percent,
    });

    // 🏅 Баллы при 100%
    if (correct == total && widget.rewardPoints > 0) {
      final scoreRef = FirebaseDatabase.instance.ref('users/$uid/score');
      await scoreRef.runTransaction((data) {
        double cur = 0.0;
        if (data is num) cur = data.toDouble();
        return Transaction.success(cur + widget.rewardPoints.toDouble());
      });
      setState(() => _showLeaf = true);
    }

    setState(() => _saving = false);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Результат теста 🌿',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Правильно: $correct из $total\nПроцент: ${percent.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (correct == total)
              AnimatedScale(
                duration: const Duration(seconds: 2),
                scale: 1.2,
                curve: Curves.elasticOut,
                child: Icon(
                  Icons.eco,
                  size: 64,
                  color: Colors.green.shade600,
                ),
              ),
            if (correct == total)
              Text(
                '\n🎉 Отлично! +${widget.rewardPoints} баллов',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green),
                textAlign: TextAlign.center,
              ),
            if (correct != total)
              const Text(
                '\nПродолжай учиться! 💚',
                textAlign: TextAlign.center,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ок'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Вернуться'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Пока нет вопросов 🌱')),
      );
    }

    final q = widget.questions[_index];
    final selected = _answers[_index];
    final progress = (_index + 1) / widget.questions.length;

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(
        offsetFactor: 1.1,
        waveSpeed: 0.7,
        moveDuration: const Duration(seconds: 5),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔹 Верхняя панель
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.green),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1C),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 🔹 Прогресс
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    color: const Color(0xFF63D471),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 20),

                // 🔹 Контент
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Вопрос ${_index + 1} из ${widget.questions.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3DA56F),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                q['question'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 🔹 Варианты ответов
                        Expanded(
                          child: ListView.builder(
                            itemCount: (q['options'] as List).length,
                            itemBuilder: (context, i) {
                              final opt = q['options'][i] as String;
                              final isSelected = selected == i;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF81C784).withOpacity(0.15)
                                      : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF81C784)
                                        : Colors.grey.shade300,
                                    width: 1.2,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? const Color(0xFF3DA56F)
                                        : Colors.grey,
                                  ),
                                  title: Text(
                                    opt,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected
                                          ? const Color(0xFF2F4F2F)
                                          : Colors.black87,
                                    ),
                                  ),
                                  onTap: () => _select(i),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 🔹 Кнопки
                if (_saving)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      if (_index > 0)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.green, width: 1.5),
                              ),
                            ),
                            onPressed: _prev,
                            child: const Text('Назад'),
                          ),
                        ),
                      if (_index > 0) const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF63D471),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: selected == null
                              ? null
                              : (_index < widget.questions.length - 1 ? _next : _finish),
                          child: Text(
                            _index < widget.questions.length - 1
                                ? 'Далее'
                                : 'Завершить',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// =====================
/// 🌾 ВОПРОСЫ ВИКТОРИН
/// =====================

final List<Map<String, dynamic>> agroQuiz = [
  {'question': 'Что растениям нужно для жизни?', 'options': ['Свет, вода и воздух', 'Только свет', 'Только вода', 'Только воздух'], 'answer': 0},
  {'question': 'Что нужно проверить перед поливом?', 'options': ['Цвет листьев', 'Влажность почвы', 'Высоту горшка', 'Температуру'], 'answer': 1},
  {'question': 'Почему нужен дренаж в горшке?', 'options': ['Чтобы удерживать воду', 'Чтобы корни не гнили', 'Чтобы растение быстрее росло', 'Чтобы меньше поливать'], 'answer': 1},
  {'question': 'Когда лучше пересаживать растения?', 'options': ['Зимой', 'Весной', 'Осенью', 'Летом'], 'answer': 1},
  {'question': 'Что бывает, если перелить растение?', 'options': ['Оно растёт быстрее', 'Корни могут загнить', 'Оно цветёт чаще', 'Почва становится рыхлой'], 'answer': 1},
  {'question': 'Для чего нужен солнечный свет растениям?', 'options': ['Чтобы греться', 'Чтобы питаться', 'Чтобы отдыхать', 'Чтобы охлаждаться'], 'answer': 1},
  {'question': 'Какой грунт любят растения?', 'options': ['Твёрдый как камень', 'Питательный и рыхлый', 'Песчаный без воды', 'Мокрый и липкий'], 'answer': 1},
  {'question': 'Что помогает воздуху попадать к корням?', 'options': ['Плотная почва', 'Рыхление земли', 'Много воды', 'Пластиковая крышка'], 'answer': 1},
  {'question': 'Зачем растениям удобрения?', 'options': ['Чтобы им было вкусно', 'Чтобы они получали питание', 'Чтобы пахли сильнее', 'Чтобы не пить воду'], 'answer': 1},
  {'question': 'Что происходит ночью с растениями?', 'options': ['Они спят', 'Дышат и отдыхают', 'Светятся', 'Не дышат вообще'], 'answer': 1},
  {'question': 'Какая вода лучше для полива?', 'options': ['Холодная', 'Тёплая и отстоянная', 'Газированная', 'Соленая'], 'answer': 1},
  {'question': 'Что помогает растению стоять прямо?', 'options': ['Корни', 'Цветы', 'Листья', 'Плоды'], 'answer': 0},
  {'question': 'Что бывает, если растению не хватает света?', 'options': ['Оно бледнеет и вытягивается', 'Растёт быстрее', 'Темнеет', 'Начинает пахнуть'], 'answer': 0},
  {'question': 'Чем полезны листья?', 'options': ['Украшают комнату', 'Дышат и питаются светом', 'Держат стебель', 'Пугают вредителей'], 'answer': 1},
  {'question': 'Что делать, если листья покрылись пылью?', 'options': ['Полить сильнее', 'Протереть мягкой тряпкой', 'Посыпать песком', 'Оставить как есть'], 'answer': 1},
];

final List<Map<String, dynamic>> financeQuiz = [
  {'question': 'Что такое деньги?', 'options': ['Игра', 'Средство обмена', 'Украшение', 'Магия'], 'answer': 1},
  {'question': 'Что такое карманные деньги?', 'options': ['Зарплата', 'Деньги ребёнка для личных трат', 'Кредит', 'Подарок всегда'], 'answer': 1},
  {'question': 'Почему полезно копить?', 'options': ['Чтобы купить всё сразу', 'Чтобы накопить на цель', 'Чтобы не тратить вообще', 'Чтобы показать друзьям'], 'answer': 1},
  {'question': 'Что такое бюджет?', 'options': ['План доходов и расходов', 'Копилка', 'Игра про деньги', 'Книга'], 'answer': 0},
  {'question': 'Что помогает не тратить лишнего?', 'options': ['Список покупок', 'Игнорирование цен', 'Покупка по настроению', 'Хождение без цели'], 'answer': 0},
  {'question': 'Как можно заработать?', 'options': ['Помогая и работая', 'Просить у всех', 'Играть в игры', 'Брать без спроса'], 'answer': 0},
  {'question': 'Почему важно записывать расходы?', 'options': ['Чтобы забывать', 'Чтобы понимать, куда уходят деньги', 'Чтобы тратить больше', 'Чтобы запутаться'], 'answer': 1},
  {'question': 'Что делает банк?', 'options': ['Прячет деньги навсегда', 'Хранит и помогает управлять деньгами', 'Дарит деньги', 'Продаёт монеты'], 'answer': 1},
  {'question': 'Что значит экономить?', 'options': ['Тратить всё', 'Покупать только нужное', 'Игнорировать цены', 'Покупать лишнее'], 'answer': 1},
  {'question': 'Что помогает накопить быстрее?', 'options': ['План и цель', 'Покупки каждый день', 'Долги', 'Лень'], 'answer': 0},
  {'question': 'Что делать, если хочется дорогую вещь?', 'options': ['Попросить', 'Подождать и накопить', 'Взять в долг', 'Забыть'], 'answer': 1},
  {'question': 'Что значит “доход”?', 'options': ['Сколько потратил', 'Сколько заработал', 'Сколько потерял', 'Сколько подарил'], 'answer': 1},
  {'question': 'Что значит “расход”?', 'options': ['То, что заработал', 'То, что потратил', 'То, что сохранил', 'То, что получил'], 'answer': 1},
  {'question': 'Зачем нужна копилка?', 'options': ['Чтобы собирать деньги на цель', 'Чтобы играть', 'Чтобы тратить всё', 'Чтобы хранить игрушки'], 'answer': 0},
  {'question': 'Что лучше: думать перед покупкой или сразу брать?', 'options': ['Думать', 'Брать сразу', 'Ждать скидок', 'Смотреть на упаковку'], 'answer': 0},
];

final List<Map<String, dynamic>> ecologyQuiz = [
  {'question': 'Что значит “экология”?', 'options': ['Изучение природы и её защиты', 'Про животных только', 'Про камни', 'Про деньги'], 'answer': 0},
  {'question': 'Что значит сортировать мусор?', 'options': ['Разделять по контейнерам', 'Смешивать всё', 'Выбрасывать в реку', 'Сжигать'], 'answer': 0},
  {'question': 'Почему важно экономить воду?', 'options': ['Потому что это дорого', 'Чтобы сохранить природу', 'Чтобы кран не шумел', 'Чтобы не мыть руки'], 'answer': 1},
  {'question': 'Зачем нужны деревья?', 'options': ['Дают тень и чистят воздух', 'Мешают солнцу', 'Занимают место', 'Никак не полезны'], 'answer': 0},
  {'question': 'Что можно сделать с бумагой после использования?', 'options': ['Выбросить', 'Сдать на переработку', 'Сжечь', 'Спрятать'], 'answer': 1},
  {'question': 'Что помогает природе дома?', 'options': ['Выключать свет, когда не нужен', 'Оставлять воду включенной', 'Покупать пластик', 'Выбрасывать еду'], 'answer': 0},
  {'question': 'Почему важно перерабатывать отходы?', 'options': ['Чтобы мусора стало меньше', 'Чтобы делать игрушки', 'Чтобы было весело', 'Чтобы шумело'], 'answer': 0},
  {'question': 'Что можно сажать на подоконнике?', 'options': ['Зелень, цветы', 'Пластик', 'Бумагу', 'Камни'], 'answer': 0},
  {'question': 'Что произойдет, если вырубить все деревья?', 'options': ['Воздух станет грязнее', 'Будет больше теней', 'Ничего', 'Появятся горы'], 'answer': 0},
  {'question': 'Как можно помочь животным?', 'options': ['Кормить и не вредить им', 'Пугать', 'Ловить ради интереса', 'Оставлять мусор'], 'answer': 0},
  {'question': 'Что лучше использовать вместо пакетов?', 'options': ['Многоразовую сумку', 'Пакеты каждый раз', 'Пакеты с надписями', 'Любые мешки'], 'answer': 0},
  {'question': 'Какой транспорт экологичный?', 'options': ['Велосипед и самокат', 'Автомобиль', 'Самолёт', 'Катер'], 'answer': 0},
  {'question': 'Что нельзя выбрасывать в природу?', 'options': ['Батарейки и пластик', 'Яблоки', 'Листья', 'Камни'], 'answer': 0},
  {'question': 'Как можно экономить энергию?', 'options': ['Выключать свет и приборы', 'Всё включать сразу', 'Оставлять свет ночью', 'Использовать телевизор всегда'], 'answer': 0},
  {'question': 'Почему важно учить детей экологии?', 'options': ['Чтобы они берегли природу', 'Чтобы они ничего не делали', 'Чтобы шумели', 'Чтобы мусорили'], 'answer': 0},
];
