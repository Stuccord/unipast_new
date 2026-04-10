import 'package:flutter/material.dart';

class LookupData {
  static const List<Map<String, dynamic>> universities = [
    {
      'id': '11111111-1111-1111-1111-111111111111',
      'name': 'Koforidua Technical University',
      'type': 'Technical'
    },
    {
      'id': '11111111-1111-1111-1111-111111111112',
      'name': 'KNUST',
      'type': 'Public'
    },
    {
      'id': '11111111-1111-1111-1111-111111111113',
      'name': 'University of Ghana, Legon',
      'type': 'Public'
    },
    {
      'id': '11111111-1111-1111-1111-111111111114',
      'name': 'University of Cape Coast',
      'type': 'Public'
    },
    {
      'id': '11111111-1111-1111-1111-111111111115',
      'name': 'University of Education, Winneba',
      'type': 'Public'
    },
    {
      'id': '11111111-1111-1111-1111-111111111116',
      'name': 'UPSA',
      'type': 'Public'
    },
    {
      'id': '11111111-1111-1111-1111-111111111117',
      'name': 'Ashesi University',
      'type': 'Private'
    },
    {
      'id': '11111111-1111-1111-1111-111111111118',
      'name': 'Central University',
      'type': 'Private'
    },
    {
      'id': '11111111-1111-1111-1111-111111111119',
      'name': 'Takoradi Technical University',
      'type': 'Technical'
    },
    {
      'id': '11111111-1111-1111-1111-11111111111a',
      'name': 'Accra Technical University',
      'type': 'Technical'
    },
  ];

  static const List<String> categories = [
    'All',
    'Technical',
    'Public',
    'Private'
  ];

  static const List<Map<String, dynamic>> faculties = [
    {
      'id': '22222222-2222-2222-2222-222222222221',
      'name': 'Engineering',
      'icon': Icons.engineering
    },
    {
      'id': '22222222-2222-2222-2222-222222222222',
      'name': 'Science',
      'icon': Icons.science
    },
    {
      'id': '22222222-2222-2222-2222-222222222223',
      'name': 'Business',
      'icon': Icons.business_center
    },
    {
      'id': '22222222-2222-2222-2222-222222222224',
      'name': 'Arts & Social Sciences',
      'icon': Icons.palette
    },
    {
      'id': '22222222-2222-2222-2222-222222222225',
      'name': 'Education',
      'icon': Icons.menu_book
    },
    {
      'id': '22222222-2222-2222-2222-222222222226',
      'name': 'Health Sciences',
      'icon': Icons.health_and_safety
    },
    {
      'id': '22222222-2222-2222-2222-222222222227',
      'name': 'Law',
      'icon': Icons.gavel
    },
    {
      'id': '22222222-2222-2222-2222-222222222228',
      'name': 'Computing & IT',
      'icon': Icons.computer
    },
  ];

  static const List<Map<String, String>> programmes = [
    {'id': '33333333-3333-3333-3333-333333333331', 'name': 'Computer Science'},
    {
      'id': '33333333-3333-3333-3333-333333333332',
      'name': 'Electrical Engineering'
    },
    {
      'id': '33333333-3333-3333-3333-333333333333',
      'name': 'Mechanical Engineering'
    },
    {'id': '33333333-3333-3333-3333-333333333334', 'name': 'Civil Engineering'},
    {
      'id': '33333333-3333-3333-3333-333333333335',
      'name': 'Business Administration'
    },
    {'id': '33333333-3333-3333-3333-333333333336', 'name': 'Accounting'},
    {'id': '33333333-3333-3333-3333-333333333337', 'name': 'Economics'},
    {'id': '33333333-3333-3333-3333-333333333338', 'name': 'Education Studies'},
    {'id': '33333333-3333-3333-3333-333333333339', 'name': 'Nursing'},
    {'id': '33333333-3333-3333-3333-33333333333a', 'name': 'Law'},
    {'id': '33333333-3333-3333-3333-33333333333b', 'name': 'IT & Networking'},
    {'id': '33333333-3333-3333-3333-33333333333c', 'name': 'Applied Biology'},
  ];

  static String getUniversityName(String id) {
    return universities.firstWhere((e) => e['id'] == id,
        orElse: () => {'name': id})['name'] as String;
  }

  static String getFacultyName(String id) {
    return faculties.firstWhere((e) => e['id'] == id,
        orElse: () => {'name': id})['name'] as String;
  }

  static String getProgrammeName(String id) {
    return programmes.firstWhere((e) => e['id'] == id,
        orElse: () => {'name': id})['name']!;
  }
}
