import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = [
      "Nhóm 1",
      "Nhóm 2",
      "Nhóm 3",
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton(
              onPressed: () {
                // TODO: mở màn hình tạo nhóm
              },
              child: const Text("Tạo nhóm mới"),
            ),
            const Text("Welcome"),
            ElevatedButton(
              onPressed: () {
                // TODO: mở tin nhắn
              },
              child: const Text("Tin nhắn"),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: mở thông báo
              },
              child: const Text("Thông báo"),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Danh sách nhóm",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        color: Colors.grey[300],
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              color: Colors.red[900],
                              alignment: Alignment.center,
                              child: const Text(
                                "Avt",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                groups[index],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            Icon(Icons.change_history,
                                color: Colors.red[900], size: 28),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400],
              ),
              onPressed: () {
                // TODO: mở cài đặt
              },
              child: const Text("Cài đặt"),
            ),
          )
        ],
      ),
    );
  }
}
