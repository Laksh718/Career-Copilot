import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:career_copilot/models/application.dart';
import 'package:career_copilot/widgets/textured_background.dart';
import 'package:career_copilot/widgets/application_card.dart';

void main() {
  group('OpportunityCategory & Model Tests', () {
    test('OpportunityCategory has correct metadata and colors', () {
      expect(OpportunityCategory.job.label, 'Job / Internship');
      expect(OpportunityCategory.hackathon.label, 'Hackathon');
      expect(OpportunityCategory.event.label, 'Tech Event / Workshop');
      expect(OpportunityCategory.contest.label, 'Coding Contest');

      expect(OpportunityCategory.hackathon.shortLabel, 'Hackathon');
      expect(OpportunityCategory.event.shortLabel, 'Event');
      expect(OpportunityCategory.contest.shortLabel, 'Contest');

      expect(OpportunityCategory.job.icon, Icons.work_rounded);
      expect(OpportunityCategory.hackathon.icon, Icons.terminal_rounded);
      expect(OpportunityCategory.event.icon, Icons.event_note_rounded);
      expect(OpportunityCategory.contest.icon, Icons.emoji_events_rounded);
    });

    test('Application serializes and deserializes category correctly', () {
      final hackathon = Application(
        id: 'hack-1',
        company: 'ETHGlobal',
        role: 'Autonomous Agent Track',
        category: OpportunityCategory.hackathon,
        deadline: 'Nov 20, 2026',
        interviewDate: 'Nov 22, 2026',
        interviewTime: '3:00 PM',
        createdAt: DateTime.now(),
        stipend: '\$15,000 Pool',
      );

      final json = hackathon.toJson();
      expect(json['category'], 'hackathon');

      final reconstructed = Application.fromJson(json);
      expect(reconstructed.category, OpportunityCategory.hackathon);
      expect(reconstructed.company, 'ETHGlobal');
      expect(reconstructed.stipend, '\$15,000 Pool');
    });

    test('Application.fromJson backwards-compatibility detects category from keywords', () {
      final legacyHackathonJson = {
        'id': 'legacy-1',
        'company': 'Smart India Hackathon',
        'role': 'Smart Automation Track',
        'deadline': 'Dec 1, 2026',
        'interviewDate': '',
        'interviewTime': '',
        'status': 'applied',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final parsed = Application.fromJson(legacyHackathonJson);
      expect(parsed.category, OpportunityCategory.hackathon);

      final legacyEventJson = {
        'id': 'legacy-2',
        'company': 'Google Cloud Summit',
        'role': 'AI & Serverless Architect Keynote',
        'deadline': '',
        'interviewDate': 'Oct 15, 2026',
        'interviewTime': '10:00 AM',
        'status': 'applied',
        'createdAt': DateTime.now().toIso8601String(),
      };

      final parsedEvent = Application.fromJson(legacyEventJson);
      expect(parsedEvent.category, OpportunityCategory.event);
    });
  });

  group('Category Filter Logic Tests', () {
    final testApps = [
      Application(
        id: '1',
        company: 'Google',
        role: 'SWE Intern',
        category: OpportunityCategory.job,
        createdAt: DateTime.now(),
      ),
      Application(
        id: '2',
        company: 'Devpost',
        role: 'Agentic AI Hackathon',
        category: OpportunityCategory.hackathon,
        createdAt: DateTime.now(),
      ),
      Application(
        id: '3',
        company: 'AWS Summit',
        role: 'Cloud Architect Workshop',
        category: OpportunityCategory.event,
        createdAt: DateTime.now(),
      ),
      Application(
        id: '4',
        company: 'Codeforces',
        role: 'Global Round 28',
        category: OpportunityCategory.contest,
        createdAt: DateTime.now(),
      ),
    ];

    test('Filter by each category correctly', () {
      final jobs = testApps.where((a) => a.category == OpportunityCategory.job).toList();
      expect(jobs.length, 1);
      expect(jobs.first.company, 'Google');

      final hacks = testApps.where((a) => a.category == OpportunityCategory.hackathon).toList();
      expect(hacks.length, 1);
      expect(hacks.first.company, 'Devpost');

      final events = testApps.where((a) => a.category == OpportunityCategory.event).toList();
      expect(events.length, 1);
      expect(events.first.company, 'AWS Summit');

      final contests = testApps.where((a) => a.category == OpportunityCategory.contest).toList();
      expect(contests.length, 1);
      expect(contests.first.company, 'Codeforces');
    });
  });

  group('Widget Tests for TexturedBackground and ApplicationCard', () {
    testWidgets('TexturedBackground renders in light and dark mode without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: TexturedBackground(
              child: Text('Light Mode Test'),
            ),
          ),
        ),
      );

      expect(find.text('Light Mode Test'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: TexturedBackground(
              child: Text('Dark Mode Test'),
            ),
          ),
        ),
      );

      expect(find.text('Dark Mode Test'), findsOneWidget);
    });

    testWidgets('ApplicationCard renders category badge and icons', (tester) async {
      final hackathon = Application(
        id: 'hack-card-1',
        company: 'ETHGlobal',
        role: 'DeFi Agent Track',
        category: OpportunityCategory.hackathon,
        deadline: 'Nov 20, 2026',
        interviewDate: 'Nov 22, 2026',
        interviewTime: '2:00 PM',
        createdAt: DateTime.now(),
        stipend: '\$20,000 Bounty',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApplicationCard(
              application: hackathon,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('ETHGlobal'), findsOneWidget);
      expect(find.text('DeFi Agent Track'), findsOneWidget);
      expect(find.text('HACKATHON'), findsOneWidget);
      expect(find.text('\$20,000 Bounty'), findsOneWidget);
      expect(find.byIcon(Icons.terminal_rounded), findsWidgets);
    });
  });
}
