import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STA App 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'STA App 2026 Home Page'),
    );
  }
}

class Announcement {
  final String title;
  final String description;

  Announcement({required this.title, required this.description});

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      title: json['title'] as String? ?? '',
      description: json['content'] as String? ?? json['description'] as String? ?? '',
    );
  }
}

class Place {
  final String city;
  final String country;

  Place({required this.city, required this.country});

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
    );
  }
}

class Food {
  final String name;
  final String nationality;

  Food({required this.name, required this.nationality});

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['name'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const String announcementsUrl = 'https://getannouncementsethan-4vxvhm267q-uc.a.run.app';
  static const String placesUrl = 'https://getbestplaces-4vxvhm267q-uc.a.run.app';
  static const String foodsUrl = 'https://getbestfoods-4vxvhm267q-uc.a.run.app';
  static const String setPlaceUrl = 'https://setbestplaces-4vxvhm267q-uc.a.run.app'; // Fixed endpoint name from prompt logic

  late Future<List<Announcement>> _announcementsFuture;
  late Future<List<Place>> _placesFuture;
  late Future<List<Food>> _foodsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _announcementsFuture = fetchAnnouncements();
      _placesFuture = fetchPlaces();
      _foodsFuture = fetchFoods();
    });
  }

  Future<List<Announcement>> fetchAnnouncements() async {
    final uri = Uri.parse(announcementsUrl);
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Failed to load announcements');
    final raw = jsonDecode(response.body);
    final rawAnnouncements = raw['data']['announcements'] as List<dynamic>;
    return rawAnnouncements.map((item) => Announcement.fromJson(item)).toList();
  }

  Future<List<Place>> fetchPlaces() async {
    final uri = Uri.parse(placesUrl);
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Failed to load places');
    final raw = jsonDecode(response.body);
    final rawPlaces = raw['data']['places'] as List<dynamic>;
    return rawPlaces.map((item) => Place.fromJson(item)).toList();
  }

  Future<List<Food>> fetchFoods() async {
    final uri = Uri.parse(foodsUrl);
    final response = await http.get(uri);
    if (response.statusCode != 200) throw Exception('Failed to load foods');
    final raw = jsonDecode(response.body);
    final rawFoods = raw['data']['bestFoods'] as List<dynamic>;
    return rawFoods.map((item) => Food.fromJson(item)).toList();
  }

  // Logic to send data to your Cloud Function
  Future<void> _submitPlace(String city, String country) async {
    try {
      final response = await http.post(
        Uri.parse(setPlaceUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'data': {'city': city, 'country': country}
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Place added successfully!')),
          );
        }
        _refreshData(); // Refresh the list after adding
      } else {
        throw Exception('Failed to add place');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Logic to send food data to your Cloud Function
  Future<void> _submitFood(String name, String nationality) async {
    try {
      final response = await http.post(
        Uri.parse('https://setbestfoods-4vxvhm267q-uc.a.run.app'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'nationality': nationality,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Food added successfully!')),
          );
        }
        _refreshData(); // Refresh the list after adding
      } else {
        throw Exception('Failed to add food (Status: ${response.statusCode}, Response: ${response.body})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Dialog Form for User Input
  void _showAddPlaceDialog() {
    final cityController = TextEditingController();
    final countryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Best Place', style: TextStyle(color: Color(0xFF800000))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            TextField(
              controller: countryController,
              decoration: const InputDecoration(labelText: 'Country'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800000)),
            onPressed: () {
              if (cityController.text.isNotEmpty && countryController.text.isNotEmpty) {
                _submitPlace(cityController.text, countryController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog Form for Adding Food
  void _showAddFoodDialog() {
    final nameController = TextEditingController();
    final nationalityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Best Food', style: TextStyle(color: Color(0xFF800000))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: nationalityController,
              decoration: const InputDecoration(labelText: 'Nationality'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800000)),
            onPressed: () {
              if (nameController.text.isNotEmpty && nationalityController.text.isNotEmpty) {
                _submitFood(nameController.text, nationalityController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Best Places';
      case 2:
        return 'Best Foods';
      default:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(announcementsFuture: _announcementsFuture, getCurrentDate: _getCurrentDate),
      BestPlacesPage(placesFuture: _placesFuture),
      BestFoodsPage(foodsFuture: _foodsFuture),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: Text(
                _getPageTitle(),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF800000),
              actions: _selectedIndex == 1
                  ? [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _showAddPlaceDialog,
                        tooltip: 'Add Best Place',
                      ),
                    ]
                  : _selectedIndex == 2
                      ? [
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _showAddFoodDialog,
                            tooltip: 'Add Best Food',
                          ),
                        ]
                      : null,
            ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Best Places'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Best Foods'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF800000),
        onTap: _onItemTapped,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// --- STATLESS PAGE WIDGETS REMAIN SAME ---

class HomePage extends StatelessWidget {
  final Future<List<Announcement>> announcementsFuture;
  final String Function() getCurrentDate;
  const HomePage({super.key, required this.announcementsFuture, required this.getCurrentDate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF800000),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB8860B), width: 3),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome to St. Augustine', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Today is a beautiful Day 3', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
                  Text('Today\'s Date: ${getCurrentDate()}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Announcements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Announcement>>(
                    future: announcementsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                      final items = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: items.map((a) => _buildAnnouncementCard(title: a.title, description: a.description)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard({required String title, required String description}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
        const SizedBox(height: 8),
        Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
      ]),
    );
  }
}

class BestPlacesPage extends StatelessWidget {
  final Future<List<Place>> placesFuture;
  const BestPlacesPage({super.key, required this.placesFuture});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF800000),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB8860B), width: 3),
              ),
              padding: const EdgeInsets.all(24.0),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Best Places to Visit', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('Discover amazing destinations around the world', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recommended Destinations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Place>>(
                    future: placesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                      final items = snapshot.data ?? [];
                      return Column(
                        children: items.map((p) => _buildPlaceCard(city: p.city, country: p.country)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard({required String city, required String country}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Row(children: [
        const Icon(Icons.location_on, color: Color(0xFF800000)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(city, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
          Text(country, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ]),
      ]),
    );
  }
}

class BestFoodsPage extends StatelessWidget {
  final Future<List<Food>> foodsFuture;
  const BestFoodsPage({super.key, required this.foodsFuture});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF800000),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB8860B), width: 3),
              ),
              padding: const EdgeInsets.all(24.0),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Best Foods to Try', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text('Discover delicious cuisines from around the world', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recommended Foods', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Food>>(
                    future: foodsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                      final items = snapshot.data ?? [];
                      return Column(
                        children: items.map((f) => _buildFoodCard(name: f.name, nationality: f.nationality)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard({required String name, required String nationality}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Row(children: [
        const Icon(Icons.restaurant, color: Color(0xFF800000)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
          Text(nationality, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ]),
      ]),
    );
  }
}
