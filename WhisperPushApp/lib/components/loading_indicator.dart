import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? text;
  final double size;

  const LoadingIndicator({super.key, this.text, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 3,
            ),
          ),
          if (text != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                text!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}
