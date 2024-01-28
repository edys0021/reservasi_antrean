import 'package:flutter/material.dart';

class ErrPage extends StatelessWidget {
  const ErrPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          Container(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
              colors: [
                Color.fromRGBO(23, 110, 167, 1),
                Color.fromRGBO(25, 118, 190, 1),
                Color.fromRGBO(27, 126, 203, 1),
                Color.fromRGBO(29, 135, 216, 1),
                Color.fromRGBO(31, 143, 229, 1)
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            )),
            height: 50,
            width: MediaQuery.of(context).size.width,
            child: const Center(
                child: Text("Reservasi Antrean",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold))),
          ),
          Expanded(
              child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * .1,
                left: 12,
                right: 12),
            child: Column(children: [
              Image(
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width * .7,
                  image: const AssetImage('assets/notfound.png')),
              const SizedBox(height: 24),
              const Text('Halaman Tidak Tersedia',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 21.0,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Pastikan koneksi internet anda stabil untuk melanjutkan layanan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ]),
          ))
        ],
      );
  }
}
