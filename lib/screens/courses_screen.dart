import 'package:flutter/material.dart';
import '../models/article_model.dart';
import 'article_screen.dart';
import 'quiz_screen.dart';
import 'quiz_history.dart';
import '../widgets/leaf_background.dart';

/// ======== СПИСОК КУРСОВ ========
final List<Map<String, dynamic>> gardenCourses = [
  {
    'id': 'c1',
    'title': '🌱 Основы ухода за растениями',
    'subtitle': 'Полив, удобрения и пересадка в домашних условиях',
    'icon': Icons.grass,
    'color': Colors.green,
    'content':
    'Полив — главный элемент ухода. Проверяй влажность почвы, не заливай. Весной пересаживай, осенью подкармливай. 🌿',
  },
  {
    'id': 'c2',
    'title': '🌍 Экология и забота о планете',
    'subtitle': 'Как сортировать мусор и экономить ресурсы',
    'icon': Icons.eco,
    'color': Colors.teal,
    'content':
    'Маленькие шаги имеют значение: сортируй отходы, выключай свет, экономь воду. Это вклад в будущее природы. 🌎',
  },
  {
    'id': 'c3',
    'title': '💰 Финансовая грамотность',
    'subtitle': 'Учись копить и тратить разумно',
    'icon': Icons.savings,
    'color': Colors.amber,
    'content':
    'Деньги — инструмент, а не цель. Планируй расходы, ставь финансовые цели и учись управлять своими сбережениями. 💡',
  },
  {
    'id': 'c4',
    'title': '🍏 Здоровое питание',
    'subtitle': 'Как выращивать и употреблять полезные продукты',
    'icon': Icons.local_florist,
    'color': Colors.orange,
    'content':
    'Овощи и фрукты — источник энергии. Научись выращивать, собирать и готовить полезные блюда. 🥕',
  },
];

/// ======== ЭКРАН КУРСОВ ========
class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: LeafBackground(
        offsetFactor: 1.1,
        waveSpeed: 0.7,
        moveDuration: const Duration(seconds: 5),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView(
              children: [
                // 🔹 Заголовок
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFB9EAB1),
                      child: Icon(Icons.menu_book, color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Курсы и обучение",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                        Text(
                          "Учись, развивайся и зарабатывай 🌿",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 🔹 Раздел "Курсы"
                const Text(
                  '📗 Обучающие курсы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F4F2F),
                  ),
                ),
                const SizedBox(height: 12),

                ...gardenCourses.map((c) => _CourseCard(course: c)),

                const SizedBox(height: 30),

                // 🔹 Раздел "Викторины"
                const Text(
                  '🧩 Викторины',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F4F2F),
                  ),
                ),
                const SizedBox(height: 12),

                _QuizCard(
                  title: '🌿 Уход за растениями',
                  subtitle: 'Проверь свои знания по поливу и удобрениям',
                  color: const Color(0xFF63D471),
                  quizId: 'agro',
                ),
                _QuizCard(
                  title: '🌍 Экология',
                  subtitle: 'Проверь, как хорошо ты заботишься о планете',
                  color: const Color(0xFF63D471),
                  quizId: 'eco',
                ),
                _QuizCard(
                  title: '💰 Финансы',
                  subtitle: 'Разберись в основах финансовой грамотности',
                  color: const Color(0xFF63D471),
                  quizId: 'fin',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ======== Карточка курса ========
class _CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: course['color'].withOpacity(0.15),
          child: Icon(course['icon'], color: course['color']),
        ),
        title: Text(
          course['title'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            course['subtitle'],
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.green,
          size: 18,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleScreen(
                article: Article(
                  id: course['id'],
                  title: course['title'],
                  preview: course['subtitle'],
                  content: course['content'],
                  thumbnail: '',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ======== Карточка викторины ========
class _QuizCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String quizId;
  final Color color;

  const _QuizCard({
    required this.title,
    required this.subtitle,
    required this.quizId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          Text(title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  List<Map<String, dynamic>> selectedQuiz = [];
                  if (quizId == 'agro') selectedQuiz = agroQuiz;
                  if (quizId == 'eco') selectedQuiz = ecologyQuiz;
                  if (quizId == 'fin') selectedQuiz = financeQuiz;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        quizId: quizId,
                        title: title,
                        questions: selectedQuiz,
                      ),
                    ),
                  );
                },
                child: const Text('Пройти'),
              ),
              IconButton(
                icon: const Icon(
                  Icons.history_rounded,
                  color: Colors.green,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          QuizHistoryScreen(quizId: quizId, title: title),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
