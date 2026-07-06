import 'package:flutter/foundation.dart';
import '../models/contact.dart';
import '../services/database_service.dart';

class ContactProvider extends ChangeNotifier {
  List<Contact> _contacts = [];
  Contact? _selectedContact;
  bool _isLoading = false;
  String? _error;

  List<Contact> get contacts => _contacts;
  Contact? get selectedContact => _selectedContact;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Contact> get favorites => _contacts.where((c) => c.isFavorite).toList();

  final _db = DatabaseService.instance;

  Future<void> loadContacts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _contacts = await _db.getContacts();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectContact(Contact contact) {
    _selectedContact = contact;
    notifyListeners();
  }

  void clearSelection() {
    _selectedContact = null;
    notifyListeners();
  }

  Future<bool> addContact(String peerId) async {
    try {
      final contact = await _db.addContact(peerId);
      _contacts = [..._contacts, contact];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFavorite(Contact contact) async {
    final newFavorite = !contact.isFavorite;

    _contacts = _contacts.map((c) {
      if (c.id == contact.id) {
        return c.copyWith(isFavorite: newFavorite);
      }
      return c;
    }).toList();

    if (_selectedContact?.id == contact.id) {
      _selectedContact = _selectedContact!.copyWith(isFavorite: newFavorite);
    }

    notifyListeners();

    try {
      await _db.updateContact(contact.id, isFavorite: newFavorite);
    } catch (e) {
      // Revert on failure
      _contacts = _contacts.map((c) {
        if (c.id == contact.id) {
          return c.copyWith(isFavorite: !newFavorite);
        }
        return c;
      }).toList();
      notifyListeners();
    }
  }

  Future<void> removeContact(Contact contact) async {
    final oldContacts = List<Contact>.from(_contacts);

    _contacts = _contacts.where((c) => c.id != contact.id).toList();
    if (_selectedContact?.id == contact.id) {
      _selectedContact = null;
    }
    notifyListeners();

    try {
      await _db.deleteContact(contact.id);
    } catch (e) {
      _contacts = oldContacts;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
