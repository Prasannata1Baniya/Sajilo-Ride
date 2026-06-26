import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PlaceSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  Future<List<Map<String, dynamic>>>? _searchFuture;
  String _lastQuery = "";

  @override
  String get searchFieldLabel => 'Search Drop-off Location...';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().length < 3) {
      return const Center(child: Text("Type at least 3 letters to search"));
    }

    // Only trigger a new request if the query string has changed
    if (_lastQuery != query) {
      _lastQuery = query;
      _searchFuture = _performSearch(query);
    }
    return _buildSearchResults();
  }

  Future<List<Map<String, dynamic>>> _performSearch(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&countrycodes=np');
    final response = await http.get(url, headers: {'User-Agent': 'com.prasannata.sajilo_ride'});

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => {
        'display_name': item['display_name'],
        'lat': double.parse(item['lat']),
        'lon': double.parse(item['lon']),
      }).toList();
    }
    return [];
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No results found."));
        }

        final results = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orangeAccent),
                title: Text(item['display_name'].split(',')[0], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(item['display_name'].split(',').skip(1).join(','), maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => close(context, item),
              ),
            );
          },
        );
      },
    );
  }
  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFFF9F9F9),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.orange),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),

      primaryColor: Colors.orange,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.orange,
      ),
    );
  }
}