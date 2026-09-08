import 'package:flutter/foundation.dart';
import '../models/application.dart';
import '../repositories/application_repository.dart';

class ApplicationController extends ChangeNotifier {
  final ApplicationRepository _repository;
  List<Application> _applications = [];

  ApplicationController(this._repository) {
    _loadApplications();
  }

  List<Application> get applications => _applications;

  void _loadApplications() {
    _applications = _repository.getApplications();
    notifyListeners();
  }

  Future<void> addApplication(Application app) async {
    _applications.insert(0, app);
    await _repository.saveApplications(_applications);
    notifyListeners();
  }

  Future<void> updateApplication(Application app) async {
    final index = _applications.indexWhere((element) => element.id == app.id);
    if (index != -1) {
      _applications[index] = app;
      await _repository.saveApplications(_applications);
      notifyListeners();
    }
  }

  Future<void> deleteApplication(String id) async {
    _applications.removeWhere((app) => app.id == id);
    await _repository.saveApplications(_applications);
    notifyListeners();
  }
}
