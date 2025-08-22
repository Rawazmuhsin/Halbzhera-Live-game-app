// File: lib/widgets/home/games_list.dart
// Description: List of upcoming games

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../models/scheduled_game_model.dart'; // Use your existing model
import 'game_card.dart';
import 'no_games_message.dart';

class GamesList extends StatelessWidget {
  const GamesList({super.key});

  // Sample data using your existing ScheduledGameModel
  static final List<ScheduledGameModel> upcomingGames = [
    ScheduledGameModel(
      id: 'game1',
      name: 'مێژووی کوردستان',
      description: 'تاقیکردنەوەیەک لەسەر مێژووی کوردستان و ڕووداوە گرنگەکانی',
      categoryId: 'cat1',
      categoryName: 'مێژوو',
      scheduledTime: DateTime.now().add(const Duration(minutes: 25)),
      prize: '٥٠٠,٠٠٠ دینار',
      maxParticipants: 50,
      questionsCount: 20,
      duration: 30,
      tags: ['مێژوو', 'کوردستان'],
      status: GameStatus.scheduled,
      createdAt: DateTime.now(),
      createdBy: 'admin1',
    ),
    ScheduledGameModel(
      id: 'game2',
      name: 'زانستی فیزیا',
      description: 'پرسیارەکان لەسەر بنەماکانی فیزیا و یاساکانی سروشت',
      categoryId: 'cat2',
      categoryName: 'زانست',
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      prize: '٧٥٠,٠٠٠ دینار',
      maxParticipants: 30,
      questionsCount: 25,
      duration: 45,
      tags: ['زانست', 'فیزیا'],
      status: GameStatus.scheduled,
      createdAt: DateTime.now(),
      createdBy: 'admin1',
    ),
    ScheduledGameModel(
      id: 'game3',
      name: 'ئەدەبیاتی کوردی',
      description: 'ناسینی شاعیران و نووسەرانی کورد و بەرهەمەکانیان',
      categoryId: 'cat3',
      categoryName: 'ئەدەبیات',
      scheduledTime: DateTime.now().add(const Duration(minutes: 45)),
      prize: '٣٠٠,٠٠٠ دینار',
      maxParticipants: 40,
      questionsCount: 15,
      duration: 30,
      tags: ['ئەدەبیات', 'کوردی'],
      status: GameStatus.scheduled,
      createdAt: DateTime.now(),
      createdBy: 'admin1',
    ),
    ScheduledGameModel(
      id: 'game4',
      name: 'جوگرافیای عێراق',
      description: 'زانیاری لەسەر شارەکان، ڕووبارەکان و شوێنە دیاریکراوەکان',
      categoryId: 'cat4',
      categoryName: 'جوگرافیا',
      scheduledTime: DateTime.now().add(const Duration(hours: 2)),
      prize: '٦٠٠,٠٠٠ دینار',
      maxParticipants: 35,
      questionsCount: 20,
      duration: 40,
      tags: ['جوگرافیا', 'عێراق'],
      status: GameStatus.scheduled,
      createdAt: DateTime.now(),
      createdBy: 'admin1',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'یاریەکانی ئامادە',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.lightText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.paddingL),
        upcomingGames.isEmpty
            ? const NoGamesMessage()
            : Column(
              children: List.generate(
                upcomingGames.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingL,
                  ),
                  child: GameCard(game: upcomingGames[index]),
                ),
              ),
            ),
      ],
    );
  }
}
