import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final List<Map<String, dynamic>> allMenus = [
    {
      'category': 'Hidangan',
      'name': 'Ayam Bakar',
      'desc': 'Ayam bakar bumbu meresap khas KedaiKlik.',
      'price': 25000,
      'img': 'assets/foto katalog/ayam bakar.jpg',
    },
    {
      'category': 'Hidangan',
      'name': 'Ayam Geprek',
      'desc': 'Ayam krispi dengan sambal korek pedas nampol.',
      'price': 20000,
      'img': 'assets/foto katalog/ayam geprek.jpg',
    },
    {
      'category': 'Hidangan',
      'name': 'Gudeg',
      'desc': 'Nangka muda manis gurih khas Jogja.',
      'price': 22000,
      'img': 'assets/foto katalog/Gudeg.jpg',
    },
    {
      'category': 'Cemilan',
      'name': 'Pempek',
      'desc': 'Ikan tenggiri asli dengan cuko yang pas.',
      'price': 18000,
      'img': 'assets/foto katalog/Pempek.jpg',
    },
    {
      'category': 'Cemilan',
      'name': 'Tahu Gejrot',
      'desc': 'Tahu pong dengan kuah asam pedas segar.',
      'price': 12000,
      'img': 'assets/foto katalog/Tahu Gejrot.jpg',
    },
    {
      'category': 'Cemilan',
      'name': 'Martabak Telur Mini',
      'desc': 'Cemilan renyah isi telur dan daun bawang.',
      'price': 15000,
      'img': 'assets/foto katalog/Martabak Telur Mini.jpg',
    },
    {
      'category': 'Minuman',
      'name': 'Es Teh',
      'desc': 'Teh manis segar pelepas dahaga.',
      'price': 5000,
      'img': 'assets/foto katalog/esteh.jpg',
    },
    {
      'category': 'Minuman',
      'name': 'Lemon Tea',
      'desc': 'Paduan teh dan jeruk lemon yang segar.',
      'price': 8000,
      'img': 'assets/foto katalog/lemon tea.jpg',
    },
    {
      'category': 'Minuman',
      'name': 'Matcha',
      'desc': 'Green tea latte yang creamy.',
      'price': 12000,
      'img': 'assets/foto katalog/matcha.jpg',
    },
    {
      'category': 'Minuman',
      'name': 'Caramel',
      'desc': 'Minuman manis dengan aroma caramel.',
      'price': 12000,
      'img': 'assets/foto katalog/caramel.jpg',
    },
  ];

  int cartCount = 0;
  String activeTab = 'Hidangan';

  List<Map<String, dynamic>> get filteredMenus {
    return allMenus.where((menu) => menu['category'] == activeTab).toList();
  }

  void _tambahKeKeranjang() {
    setState(() {
      cartCount++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Berhasil ditambah!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    itemCount: filteredMenus.length,
                    itemBuilder: (context, index) =>
                        _buildMenuCard(filteredMenus[index]),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 30,
              left: 24,
              right: 24,
              child: _buildCartButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Chatbot',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.chat),
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              IconButton(
                tooltip: 'Profil',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.profile),
                icon: const Icon(Icons.person_outline),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'Hidangan',
                'Cemilan',
                'Minuman',
              ].map(_buildTabItem).toList(),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10),
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.search, color: Colors.grey),
                hintText: 'Cari menu favoritmu...',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String name) {
    final isActive = activeTab == name;
    return GestureDetector(
      onTap: () => setState(() => activeTab = name),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFC8641E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[200]!,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> menu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              menu['img'],
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 90,
                height: 90,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  menu['desc'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rp ${_idr(menu['price'] as int)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFC8641E),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _tambahKeKeranjang,
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFC8641E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartButton() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFC8641E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC8641E).withAlpha(102),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Lihat Keranjang',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$cartCount Item',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _idr(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
}
